# agents/ — shared coding-agent configuration

One tracked source of truth for cross-agent instructions, skills, hooks, and
settings defaults. Read-only configuration is linked declaratively and writable
Pi settings are rendered by `mise bootstrap`.

## Layout and links

`pi/agent/` mirrors the on-disk layout under `~/.pi/agent`. Mise links the
read-only agent and extension configuration explicitly. Tracked `settings.json`
is rendered to a writable runtime copy because its extension path varies by
machine; shared `AGENTS.md` is explicit because its source lives one directory
higher.

| Source | Destination |
| --- | --- |
| `AGENTS.md` | `~/.claude/CLAUDE.md`, `~/.pi/agent/AGENTS.md` |
| `skills/` | `~/.agents/skills`, `~/.claude/skills` |
| `claude/hooks/` | `~/.claude/hooks` |
| `pi/agent/agents/*` | `~/.pi/agent/agents/*` |
| `pi/agent/subagents.json` | `~/.pi/agent/subagents.json` |
| `pi/agent/web-access.json` | `~/.pi/agent/web-access.json` |
| `pi/agent/settings.json` | rendered `~/.pi/agent/settings.json` template |

Bootstrap's conflict policy applies to the whole invocation. On a machine that
predates this migration, compare and reconcile each existing regular file,
remove only that destination, and rerun `mise bootstrap`. Do not use broad
`--force-dotfiles` as the normal fix.

Per-repository instructions: keep `AGENTS.md` canonical and add a one-line
`CLAUDE.md` containing `@AGENTS.md` where Claude Code is used.

## Ownership boundary

Repository-managed: instructions, skills, hooks, static helper scripts, and
the template used to render Pi settings. Machine-local and never linked or
tracked: rendered `settings.json`, credentials/OAuth (`auth.json`,
`.credentials.json`), sessions, histories, caches, plugin/package install
trees, `trust.json`, `hashline-stats.json`, and other mutable runtime state.

## Settings ownership

- **Claude `~/.claude/settings.json`**: registers the hooks in
  `claude/hooks/` (jujutsu detect/no-git on SessionStart/PreToolUse,
  kitty-tab on session lifecycle) via `$HOME/.claude/hooks/...` paths, which
  remain stable across this migration. The statusline was deleted 2026-07-11
  (it was linked but never referenced by settings).
- **Pi `~/.pi/agent/settings.json`**: rendered by Mise from
  `pi/agent/settings.json`. The selected mise environment supplies the
  `pi_extensions_path` template variable for the local extension checkout
  (`~/code/pi-extensions` on home/home-linux,
  `~/opencode/pi-extensions` on home-server, and
  `~/pi-extensions` on work). The remaining settings define
  provider/model/thinking, theme, package declarations, and an `npmCommand`
  that resolves Node through mise.
- **Pi `auth.json`** is always machine-local and must never be tracked. Pi JSON
  links are explicit, so adding another tracked file does not expand bootstrap
  scope accidentally.

## Retired: OpenCode

`config/opencode/` was removed after its unique content was absorbed:
the jujutsu skill (canonicalized here), its global AGENTS.md (absorbed into
`AGENTS.md`), and its `code-reviewer` agent + `no-git`/`notify` plugins
(intentionally not ported — reviewer was too language-specific for global
policy; plugin lifecycles are harness-specific). Recover from VCS history if
ever needed. On machines provisioned before the removal, delete the dangling
link: `rm ~/.config/opencode`.
