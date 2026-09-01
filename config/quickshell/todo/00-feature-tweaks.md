# Dynamic-island feature tweaks

- **Status:** planned; waiting for user go-ahead
- **Scope:** three sequential Quickshell changes in `config/quickshell/home`
- **Rule:** implement and verify one feature, then make exactly one feature commit before starting the next
- **Delegation:** use a Luna Max subagent for each implementation milestone (and keep each milestone's review/fixes inside its own commit)

## Order

1. [`01-clock-date-hover.md`](01-clock-date-hover.md) — replace the clock icon with `HH:MM`; reveal `YYYY-mm-dd` to its right on island hover.
2. [`02-launcher-island-drawer.md`](02-launcher-island-drawer.md) — move the launcher from the bottom-of-monitor panel into a downward expansion attached to the dynamic island.
3. [`03-workspace-switcher-island-drawer.md`](03-workspace-switcher-island-drawer.md) — reveal every workspace on the hovered monitor in a one-row, up-to-four-column drawer attached below the island.

## Shared constraints

- Preserve the existing centered island, compact footprint, Rose Pine theme, and click-through behavior outside visible surfaces.
- Reuse the existing power drawer's hover/animation feel rather than introducing unrelated visual systems.
- Keep monitor-local behavior monitor-local; do not create duplicate global services or extra top-level windows unless the existing architecture requires it.
- Follow `config/quickshell/AGENTS.md` for live Quickshell validation. Do not launch a second `qs` process when one is already watching the configuration.
- Run `shfmt -ci -i 2 -w` on touched shell files when `shfmt` is available. QML files are not shell-formatted.

## Per-feature workflow

For each file below:

1. Inspect the current QML/API behavior and the existing live session before editing.
2. Ask a Luna Max subagent to implement only that milestone.
3. Review the diff, reload the existing Quickshell process, and run focused visual/interaction checks.
4. Record results and any follow-up notes in that milestone file.
5. Commit only that milestone, then begin the next file.

## Progress log

- 2026-08-31: Initial roadmap written; no implementation started; awaiting approval.
