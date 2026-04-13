use std::collections::HashMap;
use zellij_tile::prelude::*;

const DEFAULT_FRAMES: &str = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏";
const DEFAULT_INTERVAL_MS: u64 = 250;
const DEFAULT_NOTIFY_ICON: &str = "●";

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

struct PluginConfig {
    /// One element per animation frame; each is one Unicode scalar.
    frames: Vec<String>,
    /// Seconds between frames.
    interval_secs: f64,
    /// Prefix shown when Claude is waiting for input.
    notify_icon: String,
}

impl Default for PluginConfig {
    fn default() -> Self {
        Self {
            frames: DEFAULT_FRAMES.chars().map(|c| c.to_string()).collect(),
            interval_secs: DEFAULT_INTERVAL_MS as f64 / 1000.0,
            notify_icon: DEFAULT_NOTIFY_ICON.to_string(),
        }
    }
}

// ---------------------------------------------------------------------------
// Per-pane session state
// ---------------------------------------------------------------------------

struct ClaudePane {
    /// Tab index this pane lives on; None until seen in a PaneManifest.
    tab_index: Option<usize>,
    /// Title set on session start, e.g. "Claude Code - myproject".
    title: String,
    /// Tab name captured at start, restored when the session ends.
    original_title: String,
    /// True while Claude is idle and waiting for input.
    notify: bool,
}

// ---------------------------------------------------------------------------
// Plugin state
// ---------------------------------------------------------------------------

struct State {
    panes: HashMap<u32, ClaudePane>,
    /// tab_index → pane_ids on that tab (rebuilt on every PaneUpdate).
    tab_to_panes: HashMap<usize, Vec<u32>>,
    tabs: Vec<TabInfo>,
    cfg: PluginConfig,
    frame: usize,
    /// Whether a set_timeout chain is currently live.
    animating: bool,
}

impl Default for State {
    fn default() -> Self {
        Self {
            panes: HashMap::new(),
            tab_to_panes: HashMap::new(),
            tabs: Vec::new(),
            cfg: PluginConfig::default(),
            frame: 0,
            animating: false,
        }
    }
}

register_plugin!(State);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

impl State {
    /// True if at least one pane is registered and not in notify state.
    fn any_working(&self) -> bool {
        self.panes
            .values()
            .any(|p| !p.notify && p.tab_index.is_some())
    }

    /// Start the animation timer if it isn't already running.
    fn start_animation(&mut self) {
        if !self.animating {
            self.animating = true;
            set_timeout(self.cfg.interval_secs);
        }
    }

    fn current_frame(&self) -> &str {
        &self.cfg.frames[self.frame % self.cfg.frames.len()]
    }

    fn tab_index_for(&self, pid: u32) -> Option<usize> {
        self.tab_to_panes
            .iter()
            .find_map(|(idx, pids)| pids.contains(&pid).then_some(*idx))
    }

    fn original_title_for(&self, tab_idx: usize) -> String {
        self.tabs
            .iter()
            .find(|t| t.position == tab_idx)
            .map(|t| t.name.clone())
            .unwrap_or_default()
    }

    fn rename_pane(&self, cp: &ClaudePane) {
        let Some(idx) = cp.tab_index else { return };
        let prefix = if cp.notify {
            self.cfg.notify_icon.as_str()
        } else {
            self.current_frame()
        };
        rename_tab_with_index(idx, format!("{} {}", prefix, cp.title));
    }

    /// Rename every tracked pane with the current frame / notify icon.
    fn rename_all(&self) {
        for cp in self.panes.values() {
            self.rename_pane(cp);
        }
    }
}

// ---------------------------------------------------------------------------
// Plugin impl
// ---------------------------------------------------------------------------

impl ZellijPlugin for State {
    fn load(&mut self, config: BTreeMap<String, String>) {
        if let Some(s) = config.get("throbber") {
            let frames: Vec<String> = s.chars().map(|c| c.to_string()).collect();
            if !frames.is_empty() {
                self.cfg.frames = frames;
            }
        }
        if let Some(s) = config.get("interval_ms") {
            if let Ok(ms) = s.parse::<u64>() {
                if ms > 0 {
                    self.cfg.interval_secs = ms as f64 / 1000.0;
                }
            }
        }
        if let Some(s) = config.get("notify_icon") {
            if !s.is_empty() {
                self.cfg.notify_icon = s.clone();
            }
        }

        subscribe(&[
            EventType::TabUpdate,
            EventType::PaneUpdate,
            EventType::PipeMessage,
            EventType::Timer,
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::TabUpdate(tabs) => {
                self.tabs = tabs;
            }

            Event::PaneUpdate(manifest) => {
                self.tab_to_panes.clear();
                for (tab_idx, panes) in &manifest.panes {
                    let ids: Vec<u32> = panes.iter().map(|p| p.id).collect();
                    self.tab_to_panes.insert(*tab_idx, ids.clone());

                    // Backfill any deferred ClaudePane entries and do the
                    // first rename now that the tab_index is known.
                    let frame = self.current_frame().to_string();
                    let notify_icon = self.cfg.notify_icon.clone();
                    for &pid in &ids {
                        if let Some(cp) = self.panes.get_mut(&pid) {
                            if cp.tab_index.is_none() {
                                cp.tab_index = Some(*tab_idx);
                                let prefix =
                                    if cp.notify { notify_icon.as_str() } else { frame.as_str() };
                                rename_tab_with_index(
                                    *tab_idx,
                                    format!("{} {}", prefix, cp.title),
                                );
                            }
                        }
                    }
                }
                if self.any_working() {
                    self.start_animation();
                }
            }

            Event::Timer(_elapsed) => {
                if self.any_working() {
                    self.frame = self.frame.wrapping_add(1);
                    self.rename_all();
                    set_timeout(self.cfg.interval_secs);
                } else {
                    // No working panes left; let the chain die.
                    self.animating = false;
                }
            }

            Event::PipeMessage(msg) => {
                if msg.name != "claude-tab" {
                    return false;
                }
                let payload = msg.payload.unwrap_or_default();
                let mut parts = payload.splitn(3, ':');
                let action = parts.next().unwrap_or("").to_string();
                let pane_id: Option<u32> = parts.next().and_then(|s| s.parse().ok());
                let data = parts.next().unwrap_or("").to_string();

                let Some(pid) = pane_id else {
                    return false;
                };

                match action.as_str() {
                    "start" => {
                        let tab_index = self.tab_index_for(pid);
                        let original_title =
                            tab_index.map(|i| self.original_title_for(i)).unwrap_or_default();
                        let frame = self.current_frame().to_string();
                        let cp = ClaudePane {
                            tab_index,
                            title: data,
                            original_title,
                            notify: false,
                        };
                        if let Some(idx) = cp.tab_index {
                            rename_tab_with_index(idx, format!("{} {}", frame, cp.title));
                        }
                        self.panes.insert(pid, cp);
                        if self.any_working() {
                            self.start_animation();
                        }
                    }

                    "notify" => {
                        if let Some(cp) = self.panes.get_mut(&pid) {
                            cp.notify = true;
                            let icon = self.cfg.notify_icon.clone();
                            let title = cp.title.clone();
                            if let Some(idx) = cp.tab_index {
                                rename_tab_with_index(idx, format!("{} {}", icon, title));
                            }
                        }
                        // Timer self-stops on the next tick if no working panes remain.
                    }

                    "restore" => {
                        if let Some(cp) = self.panes.get_mut(&pid) {
                            cp.notify = false;
                            let frame = self.current_frame().to_string();
                            let title = cp.title.clone();
                            if let Some(idx) = cp.tab_index {
                                rename_tab_with_index(idx, format!("{} {}", frame, title));
                            }
                        }
                        if self.any_working() {
                            self.start_animation();
                        }
                    }

                    "clear" => {
                        if let Some(cp) = self.panes.remove(&pid) {
                            if let Some(idx) = cp.tab_index {
                                rename_tab_with_index(idx, cp.original_title);
                            }
                        }
                        // animating corrects itself on the next timer tick.
                    }

                    _ => {}
                }
            }

            _ => {}
        }
        // Background plugin — never renders.
        false
    }

    fn render(&mut self, _rows: usize, _cols: usize) {}
}
