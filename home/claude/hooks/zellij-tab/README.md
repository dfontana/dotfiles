# zellij-tab

Claude Code tab tracking for Zellij. When a Claude session starts the tab
title is set to `⠋ Claude Code - <project>` and a braille spinner animates
while Claude is working. When Claude finishes a task and is waiting for input
the spinner is replaced with `●`, making it easy to spot which tab needs
attention. The original tab name is restored when the session ends.

## How it works

Shell hooks fire on Claude Code lifecycle events and send pipe messages to a
small background WASM plugin (loaded via `load_plugins`). The plugin maps pane
IDs to tab indices via `PaneUpdate` events, drives the animation timer with
`set_timeout`, and calls `rename_tab_with_index` to update names.

State lives entirely inside the plugin — no temp files.

## Tab states

| Tab name | Meaning |
|----------|---------|
| `⠋ Claude Code - project` *(spinning)* | Claude is actively working |
| `● Claude Code - project` | Claude needs your input |
| *(original name)* | No Claude session / session ended |

Multiple simultaneous Claude sessions across tabs each animate independently.
The animation timer is shared — it runs as long as any pane is in working state
and self-stops when all panes are idle or waiting.

## Requirements

- Zellij (any recent version)
- Rust + cargo (`rustup` recommended)
- `wasm32-wasip1` or `wasm32-wasi` Rust target (installed automatically by `build.sh`)
- `jq` (for wiring `settings.json`)
- bash 4+

## Version pinning

`plugin/Cargo.toml` pins `zellij-tile = "0.42"`. This **must match your
installed Zellij version** — the plugin ABI is version-specific. Check with:

```sh
zellij --version
```

Then update the version in `plugin/Cargo.toml` before building.

## Install

```sh
./install.sh
```

This builds the WASM plugin, installs it to `~/.config/zellij/plugins/`, and
wires the hooks in `~/.claude/settings.json`. Safe to re-run.

Then add one entry to the `load_plugins` block in `config/zellij/config.kdl`:

```kdl
load_plugins {
    zellij:link
    file:~/.config/zellij/plugins/zellij-claude-tab.wasm
}
```

Restart Zellij to activate.

## Configuration

All keys are optional. To customize, add a config block to the plugin entry in
`config.kdl`:

```kdl
file:~/.config/zellij/plugins/zellij-claude-tab.wasm {
    throbber    "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"  // each char = one frame; default shown
    interval_ms "250"             // ms between frames; default shown
    notify_icon "●"              // prefix when waiting for input; default shown
}
```

| Key | Default | Description |
|-----|---------|-------------|
| `throbber` | `⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏` | Animation frames; each Unicode character is one frame |
| `interval_ms` | `250` | Milliseconds between frames (4 fps) |
| `notify_icon` | `●` | Prefix shown when Claude is waiting for your input |

Some alternative throbber sequences:

```
⣾⣽⣻⢿⡿⣟⣯⣷   heavy braille
◐◓◑◒           arcs
|/-\           ASCII fallback
▁▂▃▄▅▆▇█▇▆▅▄▃▂  bar grow/shrink
```

## Rebuild after changes

```sh
./build.sh
```

Then restart Zellij.
