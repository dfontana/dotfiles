# Monitor-local workspace switcher drawer

- **Status:** pending; blocked until the launcher milestone is committed
- **Commit boundary:** one commit, after implementation and focused verification
- **Likely files:** `home/widgets/WorkspaceSwitcher.qml`, `home/widgets/WorkspacePreview.qml` (refactor or removal of its detached popup role), `home/Bar.qml`, and the smallest supporting component/metric changes

## Goal

Hovering the workspace trigger must reveal all workspaces belonging to that monitor, not only the currently active workspace. The switcher must grow downward from the dynamic island as an attached surface rather than appearing as a detached `PopupWindow`.

The layout is one workspace tall and at most four workspace tiles wide. If a monitor has more than four workspaces, keep the single-row constraint and provide access to the remaining workspaces without creating a second row.

## Current baseline

- `WorkspaceSwitcher.qml` derives a sorted, monitor-local workspace list but uses it only to cycle left/right and sets the preview target to `activeWorkspace` on hover.
- `WorkspacePreview.qml` is a detached `PopupWindow` anchored to the workspace button and renders one workspace's window preview.
- The switcher currently owns hover/close timers and closes the detached preview after a grace period.
- `Bar.qml`'s island `Region` covers only the compact island, so an attached switcher drawer will need coordinated visible-surface masking and geometry.

## Implementation plan

1. Keep the live monitor-local workspace model, sorting, active-workspace tracking, and existing click/keyboard-independent activation semantics. Ensure workspace objects are handled safely when Hyprland adds, removes, or reorders them.
2. Replace the single active-workspace detached popup path with one island-attached drawer owned by the workspace switcher/bar. The drawer must share the island's surface language and have no independent `PopupWindow`.
3. Render every workspace in the target monitor's current list in one horizontal row. Cap the visible row at four workspace widths; if more exist, use a bounded horizontal access mechanism rather than wrapping to a second row or hiding workspaces permanently.
4. Give each tile a clear active/selected state and a usable hit area. Clicking a tile activates that workspace; retain the current relative-cycle behavior for the compact trigger unless the implementation needs to route it through the new drawer.
5. Preserve useful preview information from the existing workspace preview where it fits, but keep each tile within the one-row density requirement. Do not allow a preview surface to detach from the island or open another shell window.
6. Use the same hover intent/close grace behavior as the island/power drawer so the pointer can travel from the trigger into the attached row without a dead gap. Moving across tiles updates highlighting without closing the drawer.
7. Extend the island input mask only over the visible switcher drawer while it is open/animating. Keep the compact exclusive zone and click-through behavior outside the island/drawer union unchanged.
8. Recalculate the row when workspace membership or active state changes; close or reconcile safely if the monitor or hovered workspace disappears.

## Acceptance checks

- Hovering the workspace trigger shows every workspace on that monitor, including inactive workspaces.
- The drawer is visibly joined to and grows out of the bottom of the island; it is never a detached pop-over and never anchored to the monitor bottom.
- The drawer is exactly one workspace tall and uses no more than four workspace columns at once. Additional workspaces remain reachable in the same row without wrapping.
- Active workspace styling updates when Hyprland changes it, including while the drawer is open.
- Clicking a workspace activates the selected monitor-local workspace; compact left/right cycling still works as before unless intentionally documented.
- Pointer travel from the trigger through the connector into the drawer does not close it; leaving the complete region closes it after the grace delay.
- Removed/reordered workspaces do not leave stale delegates, invalid selection, or an orphaned expansion.
- Only the visible island/drawer union is in the input mask, and the compact exclusive zone remains unchanged.
- The old detached workspace `PopupWindow` path is gone; Quickshell reloads without QML errors and visual captures show 1-, 4-, and (if available) more-than-4-workspace behavior.

## Verification notes

Record the monitor/workspace geometry, live reload log, hover animation result, activation result, and behavior with more than four workspaces here after implementation. If the current machine has fewer than five workspaces, document the static/code-path review for horizontal overflow instead of inventing a test fixture.

## Progress log

- 2026-08-31: Task mapped from the current active-workspace detached preview; no code changes started; blocked on launcher completion and user approval.
