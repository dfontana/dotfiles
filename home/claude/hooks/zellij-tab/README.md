# zellij-tab

Claude Code tab tracking for Zellij. When a Claude session starts the tab is
renamed to `⚡ Claude Code - <project>`. When Claude finishes a task and is
waiting for input the prefix switches to `●`, making it easy to spot which tab
needs attention at a glance. Colors restore when you send a prompt or the
session ends.

## How it works

Shell hooks fire on Claude Code lifecycle events and send pipe messages to a
small background WASM plugin (loaded via `load_plugins`). The plugin maps pane
IDs to tab indices via `PaneUpdate` events and calls `rename_tab_with_index` to
update the name.

State lives entirely inside the plugin — no temp files.

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

Then update the version in `plugin/Cargo.toml` accordingly before building.

## Install

```sh
./install.sh
```

This builds the WASM plugin, installs it to `~/.config/zellij/plugins/`, and
wires the hooks in `~/.claude/settings.json`. Safe to re-run; hook entries are
added only if missing.

Then add one entry to `config/zellij/config.kdl` (the `load_plugins` block):

```kdl
load_plugins {
    zellij:link
    file:~/.config/zellij/plugins/zellij-claude-tab.wasm
}
```

Restart Zellij to activate.

## Rebuild after changes

```sh
./build.sh
```

Then restart Zellij (plugins are loaded at session start).

## Tab states

| Tab name | Meaning |
|----------|---------|
| `⚡ Claude Code - project` | Claude is actively working |
| `● Claude Code - project` | Claude needs your input |
| *(original name)* | No Claude session / session ended |

Multiple simultaneous Claude sessions across tabs each track independently.
