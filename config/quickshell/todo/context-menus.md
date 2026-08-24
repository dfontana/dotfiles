# Shell-native system-tray menus

- **Status:** implementation-ready specification
- **Target:** `config/quickshell/home` on Quickshell 0.3.1
- **Scope:** system-tray menus only

## Goal

Replace the platform-owned menu opened by
`SystemTrayItem.display(...)` with one Rose Pine QML menu renderer. A tray menu
must open below the clicked tray icon, support the menu semantics listed in this
document, take keyboard focus, and close like a conventional desktop menu.

This is not a general context-menu framework and it is not a dynamic-island
vertical slice. The implementation must use one shell-owned `PopupWindow`, not
enlarge the bar's `PanelWindow` and not add another full-screen layer surface.

## Current state

The relevant path is:

```text
home/shell.qml
  -> one Bar.qml per Quickshell.screens entry
       -> widgets/SystemTray.qml
            -> Repeater over SystemTray.items
```

`SystemTray.qml` currently calls `modelData.activate()` for ordinary clicks and
calls `modelData.display(hostWindow, x, y)` for a right click when the item has a
menu. The latter call asks Quickshell to render a platform-owned menu. This task
must remove that call from the normal and fallback paths.

The local installation is Quickshell **0.3.1**. Its installed type metadata is
under `/usr/lib64/qt6/qml/Quickshell`. Quickshell is pre-1.0; implementation must
use the installed 0.3.1 API rather than examples for a newer version.

## Fixed product decisions

- Render only menus supplied by `SystemTrayItem`; do not create an abstraction
  for arbitrary shell-owned menus.
- Instantiate exactly one tray-menu popup for the entire shell process. Opening
  a menu on any monitor replaces or closes the menu already open elsewhere.
- Anchor the popup's left edge to the tray icon's left edge and place it 8 px
  below the icon. Allow Quickshell to flip, slide, or resize it at screen edges.
- Open menus only from clicks, never from hover.
- Use a stack in the same popup for submenus. Submenus open on click or keyboard,
  may nest to arbitrary depth, and never create cascading child windows.
- Render visible indicators only for checked entries. Checkbox and radio entries
  both use the same checkmark; partially checked entries use a dash.
- Support the core keyboard controls defined below, but not Space, Home/End,
  Tab traversal, type-ahead search, or mnemonic activation.
- Never fall back to `SystemTrayItem.display(...)`. An invalid, loading, or empty
  custom menu shows the disabled `No actions` placeholder.
- Runtime verification is required only with the currently available Steam tray
  item. Do not add a fake StatusNotifier/DBusMenu test service to this repo.

## Quickshell data contract

Quickshell exposes application-owned menu data through:

```text
SystemTray.items
  -> SystemTrayItem
       -> menu: QsMenuHandle
            -> QsMenuOpener.children
                 -> QsMenuEntry
```

Use these properties and signals:

- `SystemTrayItem.hasMenu`, `onlyMenu`, `menu`, and `activate()`;
- `SystemTrayItem.menu` directly as the root `QsMenuHandle`;
- `QsMenuOpener.menu` and `children`;
- `QsMenuEntry.text`, `icon`, `enabled`, `isSeparator`, `hasChildren`,
  `buttonType`, `checkState`, and the callable `triggered` signal;
- `QsMenuButtonType.None`, `.CheckBox`, and `.RadioButton`;
- `Qt.Unchecked`, `Qt.PartiallyChecked`, and `Qt.Checked`.

In Quickshell 0.3.1, bind the root opener directly to
`item ? item.menu : null`. Although the generated SystemTray metadata prints the
internal C++ type name `qs::dbus::dbusmenu::DBusMenuHandle`, that class inherits
`QsMenuHandle`. Passing it directly to `QsMenuOpener` acquires the handle,
initiates asynchronous DBusMenu loading, and updates `children` when loading
completes. Do not dereference `item.menu.menu`; the exported QML type also named
`DBusMenuHandle` represents a different class and is not this property type.

For a submenu, bind a new opener directly to the parent `QsMenuEntry` itself.
Do not use `DBusMenuItem.menuHandle` or manually call `sendOpened()`,
`sendClosed()`, or `sendTriggered()`. `QsMenuEntry.triggered` is a callable QML
signal: invoke `entry.triggered()` exactly once for an enabled leaf and never
for a separator, disabled entry, or entry with children. Do not reproduce the
application's D-Bus action logic.

`QsMenuOpener.children` is a live `UntypedObjectModel`; its `values` and model
notifications must drive the visible level. Creating and destroying one opener
per retained stack level acquires and releases Quickshell's menu references and
therefore drives the application's menu-open lifecycle.

## Target ownership and component boundaries

Add one exported component:

```text
home/widgets/TrayMenu.qml
```

and register it in `home/widgets/qmldir`. `TrayMenu.qml` owns all of the
following:

- the single `PopupWindow`;
- the selected `SystemTrayItem`, anchor item, and target screen;
- `open`, `toggle`, `close`, and `isOpenFor(item)` behavior;
- the root `QsMenuHandle` and submenu stack;
- row selection, scrolling, focus, animation, and state cleanup.

A private inline component inside `TrayMenu.qml` may render one menu level. Do
not export a generic menu row/model/controller. A second private file is
acceptable only if QML scoping makes the single file impractical.

Wire ownership as follows:

1. `shell.qml` creates exactly one `TrayMenu` next to `Launcher` and injects it
   into every `Bar` delegate.
2. `Bar.qml` passes that shared object and its `screen` to `SystemTray`.
3. `SystemTray.qml` asks the shared object to toggle a menu, supplying the
   `SystemTrayItem`, the clicked 24x24 tray item as the anchor, and the bar's
   screen.
4. Remove `SystemTray.hostWindow`; it exists only for the old `display()` call.

The popup must keep direct object references, not identify a tray item by its
Repeater index. Indices can change when applications register or unregister.

## Tray-icon input contract

The accepted mouse buttons remain left and right only.

| Input | Required behavior |
| --- | --- |
| Left click, `onlyMenu === false` | Call `item.activate()` if the event reaches the tray `MouseArea`. |
| Left click, `onlyMenu === true && hasMenu === true` | Toggle the custom menu if the event reaches the tray `MouseArea`. |
| Left click, `onlyMenu === true && hasMenu === false` | Do nothing. |
| Right click, `hasMenu === true` | Toggle the custom menu if the event reaches the tray `MouseArea`. |
| Right click, `hasMenu === false` | Do nothing; do not call `activate()`. |
| Middle click | Out of scope; do not call `secondaryActivate()`. |
| Wheel over tray icon | Out of scope; do not call `scroll()`. |

Clicking the same trigger while its menu is open closes it. Clicking another
tray item replaces the selected item, resets the submenu stack to that item's
root, moves the anchor, and opens the new menu. A focused Wayland popup may
consume the outside click used to dismiss it. When that happens, the consumed
physical click performs no activation or toggle; the user must click again.
This rule also applies when moving a menu between tray items or monitors.

Set the tray `MouseArea` to `hoverEnabled: true`. Add a rounded `Theme.hover`
rectangle behind a tray icon while that area contains the pointer or while
`TrayMenu.isOpenFor(modelData)` is true. It fills the existing 24x24 tray item
and uses a 12 px radius. Keep the existing icon size and passive-item opacity.

## Popup behavior and placement

Use a transparent `PopupWindow` with:

- `anchor.item` bound to the selected tray anchor;
- bottom-left anchoring and bottom-right gravity so the visible menu's left edge
  initially matches the icon's left edge;
- `anchor.margins.top: -8` and `anchor.margins.bottom: -8`; Quickshell removes
  margins from the anchor rectangle, so these negative margins move the initial
  bottom anchor point 8 px below the icon and the flipped top anchor point 8 px
  above it;
- `anchor.adjustment: PopupAdjustment.All`;
- `grabFocus: true`.

`grabFocus` is required: the popup must receive key events and Quickshell must
hide it on an outside click or focus loss. Verify both behaviors on the
installed 0.3.1 build. When `visible` becomes false for any reason, clear the
selected item, anchor, screen, submenu stack, closing state, and keyboard
selection so no icon remains highlighted.

There must be no full-screen click-catcher and no `HyprlandFocusGrab` unless the
runtime probe proves `PopupWindow.grabFocus` broken. If such a workaround is
necessary, document the observed failure next to the code; it may not replace
the anchored popup with a full-screen `PanelWindow`.

Only one popup instance exists, so process-global exclusivity follows from
ownership rather than cross-monitor coordination between multiple windows.

## Menu levels and navigation

The root level binds its opener directly to
`selectedTrayItem ? selectedTrayItem.menu : null`. Each submenu level receives
the selected parent `QsMenuEntry` itself as its `QsMenuHandle`.

- A level shows entries in the exact order supplied by `QsMenuOpener.children`.
- A row with `hasChildren` enters a submenu; it never invokes `triggered()`.
- A leaf invokes `triggered()` synchronously once, then starts closing.
- Disabled rows and separators cannot be selected or activated.
- Pointer entry over an enabled non-separator row makes it the current keyboard
  selection. Pointer exit does not close the menu and does not need to clear the
  selection.
- Submenus open only on row click, Enter, or Right Arrow; pointer hover alone
  does not enter them.
- Every submenu has a fixed 30 px first row labeled `Back` with a left chevron.
  It remains above the scrollable entry list. Clicking it or pressing Left Arrow
  pops exactly one level and restores that parent level's prior selection and
  scroll offset. Back has pointer-hover styling but is never the level's
  keyboard-selected entry; Up, Down, and Enter never select or activate it.
- If a root or submenu opener has zero children, show one 30 px disabled row
  labeled `No actions`. In a submenu it appears below the Back row.

The stack must retain parent level instances while a child is open so Back can
restore the previous level without reconstructing it.

### Keyboard contract

When a level opens, select its first enabled, non-separator entry. If no such
entry exists, leave the level unselected. Focus the active level after the popup
opens and after every push/pop.

| Key | Required behavior |
| --- | --- |
| Down | Select the next enabled non-separator row. Stop at the last selectable row. |
| Up | Select the previous enabled non-separator row. Stop at the first selectable row. |
| Enter/Return | Enter the selected submenu, or trigger and close for a selected leaf. |
| Right Arrow | Enter the selected row only when it has children; otherwise do nothing. |
| Left Arrow | Pop one submenu level; do nothing at the root. |
| Escape | Close the entire popup from any level. |

Navigation never wraps. Disable `ListView`'s built-in key navigation and move
selection only through the table above. Selection changes must call
`ListView.positionViewAtIndex(..., ListView.Contain)` or equivalent so the
selected row is visible. Explicitly accept Space, Home, End, Tab, Backtab,
printable keys, and mnemonic-like input as no-ops so they cannot move focus or
trigger default navigation. Render `QsMenuEntry.text` literally, including any
`_` or `&` characters supplied by the application.

## Layout and visual specification

All dimensions are logical QML pixels.

### Surface

- Let `availableWidth = Math.max(1, targetScreen.width - 16)` and set
  `cardWidth = Math.min(availableWidth, Math.max(220, Math.min(360,
  naturalWidth)))`. The 220 px minimum is waived only when the target screen
  cannot accommodate it.
- Map the anchor's top and bottom to global coordinates. After the 8 px popup gap
  and 8 px screen-edge margin, compute the non-negative space below and above
  within `targetScreen.y .. targetScreen.y + targetScreen.height`. Set maximum
  card height to the larger value so `PopupAdjustment.FlipY` can choose the side
  that fits best. Set card height to `Math.min(naturalHeight,
  maximumCardHeight)`; there is no row-count or percentage cap.
- Bind the scrolling viewport to the popup/card's actual constrained height,
  not only `implicitHeight`, so compositor resizing scrolls rather than clips.
- Recalculate width, height, and global anchor geometry when live menu data, the
  anchor, its window/screen, or the current stack level changes. The left-edge
  anchor remains stable unless edge adjustment is required.
- Card background: `Theme.barSurface`.
- Border: 1 px `Theme.highlightMed`.
- Radius: 12 px.
- Inner padding: 6 px on all sides.
- Do not add Caelestia blob geometry, shaders, ripples, C++ tokens, or a new
  shadow system.

### Action rows

- Height: 30 px.
- Radius: 9 px.
- Horizontal content padding: 8 px.
- Inter-column gap: 6 px.
- Label: `Theme.iconFont`, 14 px, `Theme.text`, one line,
  `Text.ElideRight`.
- Hovered or keyboard-selected background: `Theme.hover`.
- Disabled label: `Theme.muted`; disabled icons and indicators use opacity 0.45,
  and the row never receives hover/selection fill.
- Entry icon: 16x16 `IconImage` using `entry.icon` directly. Do not run the menu
  icon through desktop-entry lookup or recolor it.
- Submenu indicator: `›` (U+203A), 14 px, in `Theme.accent`; Back uses `‹`
  (U+2039) with the same size and color.
- Checked indicator: `✓` (U+2713), 14 px, in `Theme.accent` for either checkbox
  or radio when `checkState === Qt.Checked`; use `−` (U+2212) when
  `Qt.PartiallyChecked`; show nothing when `Qt.Unchecked` or
  `buttonType === QsMenuButtonType.None`.
- An icon and a check indicator may both be present. Compute level-wide leading
  columns so labels align: reserve the check column for every row if any row in
  that level has a visible check/dash, reserve the icon column if any row has an
  icon, and reserve the trailing chevron column if any row has children. Empty
  reserved cells remain transparent.

Compute each action row's natural width as 16 px row padding plus its unelided
label width, plus each active level-wide column (14 px check, 16 px icon, and
14 px chevron), plus one 6 px gap between each adjacent visible/reserved content
column. Add 12 px card padding after taking the widest row. Also compare that
result with Back's width (`12 + 16 + 14 + 6 + Back label width`) and the
placeholder's width (`12 + 16 + No actions label width`) when either is present.
Clamp the resulting `naturalWidth` with the surface formula before laying out
labels; labels consume the remaining width and elide.

### Separators, Back, placeholder, and scrollbar

- Render a separator as a 1 px `Theme.highlightMed` line with 4 px vertical and
  8 px horizontal margins, for a total 9 px separator slot. It is not
  selectable.
- Render Back as an ordinary enabled row with `Theme.text` and the specified
  `Theme.accent` left chevron. It uses pointer-hover treatment but never the
  keyboard-selection state.
- Render `No actions` with `Theme.muted`, no icon, no hover, and no keyboard
  selection.
- When content overflows, show a 3 px rounded vertical scrollbar in
  `Theme.muted` at the card's right inset. Wheel scrolling over the open menu
  scrolls this view; it is unrelated to the deferred tray-item `scroll()` API.

## Animation

Use menu-local animations; do not change `BarMetrics.animationDuration`.

- Open: 140 ms `OutCubic`, opacity 0 to 1 and scale 0.96 to 1, with the transform
  origin at the anchored top-left corner.
- Programmatic close (Escape, toggle, leaf action): synchronously disable all
  menu input, then reverse opacity/scale over 100 ms before hiding. Keep the
  selected item and anchor, and therefore `isOpenFor(item)`, until `visible`
  becomes false. A compositor-driven outside-click or focus-loss dismissal may
  hide immediately because `PopupWindow.grabFocus` controls that path.
- Push submenu: 140 ms `OutCubic` horizontal slide/fade over 16 px, child
  entering from the right and parent exiting left.
- Pop submenu: the reverse 16 px transition, parent entering from the left.
- Hover/keyboard highlight color: 120 ms color transition.

Ignore additional row activation while a push/pop or close transition is in
progress. A request for a different tray item cancels any current open/close or
stack transition, replaces all menu state with the latest request, and begins
that root's open transition. A close request always wins over a stack request.
Animation must not delay `triggered()` or `activate()`, leave an invisible
focused popup, or allow outgoing levels to accept input.

## Live updates and object lifetime

The application owns its DBus menu and may update it while open.

- Bind each level directly to its opener's live children; do not copy entries
  into a stale JavaScript action model.
- Recompute dimensions, visible columns, and selectable indices after insertion,
  removal, reordering, text/icon changes, enabled-state changes, child-state
  changes, and check-state changes.
- Preserve the selected object only while it still exists, is enabled, and is
  not a separator. Otherwise select the first enabled non-separator row.
- If the active submenu entry is removed or stops having children, pop back to
  the nearest still-valid ancestor.
- “No root remains” means the selected tray item unregistered or now has
  `hasMenu === false`; close in those cases and when its anchor item is
  destroyed.
- While `hasMenu === true`, the root opener may initially have zero children
  while its handle loads. Retain the root level, show `No actions`, and update
  from `QsMenuOpener.childrenChanged` and the live child model. A defensively
  handled null root property follows the same rule and never invokes a native
  fallback.
- `SystemTrayItem.menu` uses `hasMenuChanged` as its notify signal. If the root
  handle object changes while the item remains registered, discard the submenu
  stack and bind the root opener to the new handle. Internal menu reloads on the
  same handle arrive through the existing opener; do not access
  `item.menu.menu`.
- Ensure delegates, openers, and retained submenu levels do not keep an
  unregistered tray item alive.

## Explicitly out of scope

Do not include any of the following in this task:

- platform/native fallback via `display()` or `QsMenuAnchor`;
- generic context menus for power, tasks, workspaces, launcher results, or other
  shell controls;
- dynamic-island integration or changes to the bar's `PanelWindow` footprint,
  exclusive zone, or input mask;
- cascading or hover-open submenus;
- different visual glyphs for checkbox versus radio entries;
- indicators for unchecked entries;
- middle-click secondary activation and tray-item wheel forwarding;
- keyboard Space, Home/End, Tab, type-ahead, or mnemonic processing;
- menu search, headers, application titles, tooltips, drag gestures, or touch-
  specific behavior;
- a checked/nested DBusMenu fixture, new packages, Caelestia plugins, or C++.

## Implementation sequence

1. Add and register the globally owned `widgets/TrayMenu.qml` popup.
2. Pass it through `shell.qml` and `Bar.qml` to every `SystemTray` instance.
3. Replace `SystemTray.qml`'s click mapping and remove `hostWindow`/`display()`.
4. Add root-level rendering, exact layout/theme values, focus, and dismissal.
5. Add the arbitrary-depth stack, fixed Back row, core keyboard controls, and
   per-level scroll/selection restoration.
6. Add checked-only indicators, live-update handling, lifecycle cleanup, and
   menu-local animations.
7. Verify the acceptance criteria below against the live Quickshell process.

## Acceptance criteria

### Static and architectural

- There is exactly one `TrayMenu` instance in `shell.qml`, not one per Repeater
  delegate or monitor.
- `rg '\.display\(' config/quickshell/home` finds no tray-menu display path.
- No generic menu abstraction, test fixture, dynamic-island refactor, extra
  `PanelWindow`, or new dependency was added.
- The root opener receives only the `selectedTrayItem.menu` handle; submenu
  openers receive the parent `QsMenuEntry` itself. Every level uses
  `QsMenuOpener`, and leaf activation invokes `QsMenuEntry.triggered()` exactly
  once.
- Nested, checked, partially checked, loading/empty-opener, root-replacement,
  and live-mutation paths are code-review acceptance criteria for this
  milestone. They must be present and consistent with this specification, but
  do not require a runtime demonstration or fixture beyond Steam.

### Manual behavior with Steam

Steam is the only required runtime test application for this milestone. Its
current menu exercises ordinary rows and separators but not the required nested
or checked code paths; the absence of those rows in Steam is not permission to
omit their implementation, and no fixture is required to prove them manually.

With the existing `qs -p quickshell/home` process running:

1. Right-click Steam. A Rose Pine custom popup appears 8 px below and left-
   aligned with the icon; no platform-owned menu appears.
2. Hover rows and use Up/Down. Disabled rows and separators are skipped,
   selection clamps at the ends, and selected rows remain visible.
3. Press Escape. The popup closes, releases focus, clears selection, and removes
   the tray icon's open highlight.
4. Reopen it and click a safe leaf such as Store or Library. Its application
   action occurs once and the popup closes.
5. Reopen it and click outside. It closes without leaving an invisible input or
   keyboard grab.
6. Right-click the same trigger. If Wayland delivers the event to the tray area,
   the explicit toggle closes it; if the popup consumes the event, outside-click
   dismissal closes it and that event performs no second action.
7. Open Steam's menu on one monitor, dismiss it by clicking Steam on another,
   then click the second monitor's icon again if the dismissal click was
   consumed. At most one menu is visible, and the eventual open menu's anchor
   and highlight belong to the second monitor.
8. Confirm the menu uses the specified 30 px density, adaptive 220–360 px width,
   literal labels, separators, colors, border, radius, and fast animations.
9. Confirm normal left-click activation still works and right-click never
   activates an item that lacks a menu.

### Robustness

- Opening an empty or still-loading advertised menu shows `No actions` and
  remains closable with Escape/outside click.
- Menu changes do not produce stale rows, invalid selection, clipped selected
  rows, or multiple popups.
- Removing the selected tray item or anchor closes and cleans up the popup.
- Quickshell reloads the edited configuration without QML errors or a second
  running `qs` process. Follow `config/quickshell/AGENTS.md` for live-session
  capture and verification; do not launch another Quickshell instance while the
  existing one is watching the configuration.
- Find the existing instance and inspect its reload log instead of launching a
  test instance:

  ```sh
  qs list --all
  qs log --pid <PID from the matching config path> -t 100 --no-color
  ```

  The latest reload must end in `Configuration Loaded`, with no menu-related
  QML error after it.

## References

### Repository

- Current tray widget: `config/quickshell/home/widgets/SystemTray.qml`
- Per-screen bar: `config/quickshell/home/Bar.qml`
- Shell root: `config/quickshell/home/shell.qml`
- Theme: `config/quickshell/home/theme/Theme.qml`
- Existing anchored-popup example:
  `config/quickshell/home/widgets/WorkspacePreview.qml`
- Presentation reference only: `~/code/shell/modules/bar/popouts/TrayMenu.qml`

### Installed/online Quickshell 0.3.1 API

- Installed core metadata:
  `/usr/lib64/qt6/qml/Quickshell/quickshell-core.qmltypes`
- Installed tray metadata:
  `/usr/lib64/qt6/qml/Quickshell/Services/SystemTray/quickshell-service-statusnotifier.qmltypes`
- Installed DBusMenu metadata:
  `/usr/lib64/qt6/qml/Quickshell/DBusMenu/quickshell-dbusmenu.qmltypes`
- [PopupWindow](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupWindow/)
- [SystemTrayItem](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.SystemTray/SystemTrayItem/)
- [QsMenuOpener](https://quickshell.org/docs/v0.3.1/types/Quickshell/QsMenuOpener/)
- [QsMenuEntry](https://quickshell.org/docs/v0.3.1/types/Quickshell/QsMenuEntry/)
- [StatusNotifierItem specification](https://specifications.freedesktop.org/status-notifier-item/latest-single/)
