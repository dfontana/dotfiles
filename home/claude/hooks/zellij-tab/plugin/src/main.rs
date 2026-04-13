use std::collections::HashMap;
use zellij_tile::prelude::*;

/// State for one Claude Code session, keyed by ZELLIJ_PANE_ID.
#[derive(Default)]
struct ClaudePane {
    /// Tab index this pane lives on. None until we see it in a PaneManifest.
    tab_index: Option<usize>,
    /// Display title, e.g. "Claude Code - myproject".
    title: String,
    /// Original tab name captured at `start`, restored on `clear`.
    original_title: String,
    /// True while Claude is waiting for input (⚡ → ●).
    notify: bool,
}

#[derive(Default)]
struct State {
    /// pane_id → session state
    panes: HashMap<u32, ClaudePane>,
    /// tab_index → pane_ids on that tab (rebuilt on every PaneUpdate)
    tab_to_panes: HashMap<usize, Vec<u32>>,
    /// Latest tab list (for original_title lookup and active-tab name)
    tabs: Vec<TabInfo>,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, _config: BTreeMap<String, String>) {
        subscribe(&[
            EventType::TabUpdate,
            EventType::PaneUpdate,
            EventType::PipeMessage,
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
                    // Backfill tab_index for any deferred Claude panes.
                    for &pid in &ids {
                        if let Some(cp) = self.panes.get_mut(&pid) {
                            if cp.tab_index.is_none() {
                                cp.tab_index = Some(*tab_idx);
                                apply_rename(cp);
                            }
                        }
                    }
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
                        let original_title = self
                            .tab_to_panes
                            .iter()
                            .find_map(|(tab_idx, pids)| {
                                if pids.contains(&pid) {
                                    self.tabs
                                        .iter()
                                        .find(|t| t.position == *tab_idx)
                                        .map(|t| t.name.clone())
                                } else {
                                    None
                                }
                            })
                            .unwrap_or_default();

                        let tab_index = self
                            .tab_to_panes
                            .iter()
                            .find_map(|(tab_idx, pids)| {
                                if pids.contains(&pid) { Some(*tab_idx) } else { None }
                            });

                        let cp = ClaudePane {
                            tab_index,
                            title: data.clone(),
                            original_title,
                            notify: false,
                        };
                        // Only rename immediately if tab_index is known; otherwise
                        // PaneUpdate backfill will do it.
                        if cp.tab_index.is_some() {
                            apply_rename(&cp);
                        }
                        self.panes.insert(pid, cp);
                    }
                    "notify" => {
                        if let Some(cp) = self.panes.get_mut(&pid) {
                            cp.notify = true;
                            apply_rename(cp);
                        }
                    }
                    "restore" => {
                        if let Some(cp) = self.panes.get_mut(&pid) {
                            cp.notify = false;
                            apply_rename(cp);
                        }
                    }
                    "clear" => {
                        if let Some(cp) = self.panes.remove(&pid) {
                            if let Some(idx) = cp.tab_index {
                                rename_tab_with_index(idx, cp.original_title);
                            }
                        }
                    }
                    _ => {}
                }
            }
            _ => {}
        }
        // Background plugin — never renders, no repaint needed.
        false
    }

    fn render(&mut self, _rows: usize, _cols: usize) {
        // Background plugin: nothing to render.
    }
}

/// Call rename_tab_with_index with the correct prefix for the current state.
fn apply_rename(cp: &ClaudePane) {
    let Some(idx) = cp.tab_index else { return };
    let prefix = if cp.notify { "● " } else { "⚡ " };
    rename_tab_with_index(idx, format!("{}{}", prefix, cp.title));
}
