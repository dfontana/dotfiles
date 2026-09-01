# Clock time and date hover

- **Status:** pending; waiting for user go-ahead
- **Commit boundary:** one commit, after implementation and focused verification
- **Likely files:** `home/widgets/StatusArea.qml`, possibly a new clock component under `home/widgets/`, and only the smallest supporting metric/style changes

## Goal

Replace the compact clock glyph with a simple 24-hour `HH:MM` display. When the pointer hovers the clock item, expand the island horizontally so the clock reads:

```text
HH:MM YYYY-mm-dd
```

The date must appear to the right of the time. Leaving the clock returns the island to the compact time-only state.

## Current baseline

- `StatusArea.qml` ends with a non-interactive `CompactIconButton` containing a clock icon.
- `Bar.qml` sizes the centered island from the compact row's implicit width and already animates width changes with an `OutCubic` animation.
- No clock/date service exists; the implementation will need a live time source and minute-level refresh.

## Implementation plan

1. Extract or replace the final clock button with a clock item that owns a `Date`-based `HH:MM` formatter and a `YYYY-mm-dd` formatter.
2. Update the displayed time at minute boundaries (or with an equivalent timer that cannot leave a stale value after a minute rolls over); avoid per-second process churn.
3. Add a hover handler to the clock item. Keep the compact state text-only and show the date only while that clock hover state is active.
4. Animate the item's width/opacity in a way that composes with the existing island width animation, keeping the island centered as it grows. Do not change the island's exclusive zone or add a popup window.
5. Preserve the existing typography, vertical alignment, Rose Pine colors, and click-through mask semantics. The clock remains informational unless the current UI already assigns it an action.
6. Handle the initial value and a minute rollover deterministically, including zero-padding and 24-hour formatting independent of locale-specific AM/PM output.

## Acceptance checks

- Compact island shows `HH:MM`, never the old clock glyph.
- Compact time is exactly five characters, with leading zeroes and 24-hour hours.
- Hovering the clock expands the centered island and shows `HH:MM YYYY-mm-dd` with the date on the right.
- Date formatting is exactly four-digit year, two-digit month, two-digit day, with hyphens.
- Moving away hides the date and contracts the island smoothly; no detached surface appears.
- The minute transition updates both states without requiring a reload.
- Other status controls and the island's compact footprint remain unchanged.
- Quickshell reloads without QML errors, and a compact plus hovered capture confirms alignment and animation.

## Verification notes

Record the live-session PID/reload result and compact/hover visual results here after implementation. If monitor geometry or the current bar differs from `config/quickshell/AGENTS.md`, record the observed geometry rather than relying on stale crop coordinates.

## Progress log

- 2026-08-31: Task mapped from the current clock-icon implementation; no code changes started; awaiting approval.
