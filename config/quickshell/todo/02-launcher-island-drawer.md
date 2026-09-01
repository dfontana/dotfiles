# Launcher attached to the dynamic island

- **Status:** ready; clock milestone complete
- **Commit boundary:** one commit, after implementation and focused verification
- **Likely files:** `home/Launcher.qml`, `home/Bar.qml`, `home/components/` and/or `home/widgets/` for the attached drawer content, plus `home/shell.qml` only if ownership wiring must change

## Goal

The launcher must grow downward from the dynamic island instead of opening from the bottom edge of the monitor. The expansion should feel like the existing power controls' smooth hover drawer: one coherent island surface, an attached transition, and no detached bottom panel.

The existing launcher behavior must remain available: the process-global shortcut toggles the launcher, the launcher searches the existing desktop-entry model, Up/Down and Enter work, clicking a result launches it, and Escape/focus loss closes it.

## Current baseline

- `Launcher.qml` owns the app model, subsequence scoring, query, `GlobalShortcut`, and launch lifecycle.
- It also creates one `PanelWindow` per screen in `Variants`, restricted to the focused screen, with a card anchored to the bottom of the monitor.
- `Bar.qml` owns the centered island and currently invokes `launcherService.toggleLauncher()` from the search icon.
- The bar's `PanelWindow` is currently sized to the compact footprint and its input mask covers only the island, so the attached launcher must deliberately extend the host surface/mask without making transparent pixels intercept input.

## Implementation plan

1. Separate launcher state/service responsibilities from the old per-screen bottom `PanelWindow` presentation without duplicating the global shortcut or app model.
2. Make the launcher view an island-owned, monitor-local child of the relevant `Bar`/island. Route click and global-shortcut requests to the focused monitor's launcher instance while retaining one launcher state/query source.
3. Remove the old bottom-anchored per-screen launcher panels and any full-screen focus-grab/input surface they require. The launcher must not open out of the monitor bottom.
4. Add a downward attached drawer/card below the island. Use the power drawer's hover/animation conventions: smooth `OutCubic` growth, no elastic overshoot, and no visible gap between island and launcher surface.
5. Keep the launcher content usable while expanded: search field focus after opening, bounded result list, keyboard navigation, result hover selection, launch-and-close, Escape, focus loss, and delayed query reset after close.
6. Update the island input `Region` to include only the visible launcher expansion while open/animating, keeping unrelated transparent bar pixels click-through and the compact exclusive zone stable.
7. Ensure the card is positioned relative to the centered island and remains on-screen on every supported monitor without changing the monitor's tiled-window placement.

## Acceptance checks

- Clicking the launcher icon opens the launcher directly below the island, not at the bottom of the monitor.
- The global launcher shortcut opens/toggles the launcher on the focused monitor and focuses the search field.
- The expansion grows smoothly from the island and visually reads as one connected surface, comparable to the power drawer animation.
- The launcher can be hovered, typed into, navigated with Up/Down, activated with Enter, and dismissed with Escape or focus loss.
- Launching an application closes the attached drawer and preserves the existing delayed query reset behavior.
- Only the visible island/drawer union is in the input mask; desktop input outside it remains unaffected.
- No old launcher `PanelWindow` or bottom-of-monitor anchor remains, and no second `qs` process is started for verification.
- Quickshell reloads without QML errors; captures document closed, opening, and populated states on the focused monitor.

## Verification notes

Record the live-session PID/reload log, shortcut behavior, keyboard/focus results, and visual captures here after implementation. Explicitly note the measured drawer geometry and whether any monitor-edge adjustment was needed.

## Progress log

- 2026-09-01: Clock/date prerequisite completed; launcher milestone is ready to start.
- 2026-08-31: Task mapped from the current bottom-anchored launcher panel; no code changes started; blocked on clock completion and user approval.
