# agents/ — shared coding-agent configuration

One tracked source of truth for cross-agent instructions, skills, hooks, and
settings defaults. Read-only configuration is linked declaratively; global
instructions and supported Pi settings are rendered by `mise bootstrap`.

## Layout and links

`pi/agent/` mirrors the on-disk layout under `~/.pi/agent`. Mise links the
read-only agent and extension configuration explicitly. The global instruction
template always reads tracked `AGENTS.md`; under `MISE_ENV=work`, it also
appends ignored, machine-local `AGENTS.work.md` when that file exists.

| Source | Destination |
| --- | --- |
| `pi/agent/AGENTS.md.tmpl` | rendered `~/.claude/CLAUDE.md`, `~/.pi/agent/AGENTS.md` |
| `AGENTS.md` | tracked input to the global instruction template |
| `AGENTS.work.md` | optional ignored work-only template input |
| `skills/` | `~/.agents/skills`, `~/.claude/skills` |
| `claude/hooks/` | `~/.claude/hooks` |
| `pi/agent/agents/` | individual links under `~/.pi/agent/agents/` |
| `pi/agent/subagents.json` | `~/.pi/agent/subagents.json` |
| `pi/agent/web-access.json` | `~/.pi/agent/web-access.json` outside `work` |
| `pi/agent/settings.json` | rendered `~/.pi/agent/settings.json` outside `work` |

Bootstrap's conflict policy applies to the whole invocation. On a machine that
predates this migration, compare and reconcile each existing regular file,
remove only that destination, and rerun `mise bootstrap`. Do not use broad
`--force-dotfiles` as the normal fix.

Per-repository instructions: keep `AGENTS.md` canonical and add a one-line
`CLAUDE.md` containing `@AGENTS.md` where Claude Code is used.

## Ownership boundary

Repository-managed: generic instructions, instruction/settings templates,
skills, hooks, and static helper scripts. Machine-local and never tracked:
`AGENTS.work.md`, rendered settings, credentials/OAuth (`auth.json`,
`.credentials.json`), sessions, histories, caches, plugin/package install
trees, `trust.json`, `hashline-stats.json`, and other mutable runtime state.
The `work` profile leaves both Pi `settings.json` and `web-access.json`
unmanaged so existing work-specific values remain untouched.

## Settings ownership

- **Claude `~/.claude/settings.json`**: on `home`, `home-linux`, and
  `home-server`, rendered by Mise from `claude/settings.json`, mirroring the
  Pi arrangement below. It registers the jujutsu detect/no-git hooks on
  SessionStart/PreToolUse via `{{ env.HOME }}/.claude/hooks/...` paths. The
  kitty-tab hooks ship in `claude/hooks/` but are deliberately not registered.
  On `work` the file is unmanaged. Because Mise renders this file, Claude's
  own writes to it (`/config` changes, `feedbackSurveyState`) are discarded on
  the next bootstrap — durable preference changes belong in
  `claude/settings.json`, and machine-local ones in `settings.local.json`,
  which stays unmanaged. An optional machine-local statusline is unmanaged.
- **Pi `~/.pi/agent/settings.json`**: on `home`, `home-linux`, and
  `home-server`, rendered by Mise from `pi/agent/settings.json`. The selected
  environment supplies `pi_extensions_path` for the local extension checkout
  (`~/code/pi-extensions` on home/home-linux and
  `~/opencode/pi-extensions` on home-server). The remaining settings define
  provider/model/thinking, theme, package declarations, and an `npmCommand`
  that resolves Node through mise. On `work`, the existing regular file is
  intentionally unmanaged.
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
