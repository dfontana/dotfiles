# Dynamic-island research notes

**Status:** design research; no QML implementation changes are included in this note.

This note investigates how the local [`Synoptik`](file:///home/koss/code/Synoptik)
shell makes one bar grow into different panels, then maps that pattern onto the
current `config/quickshell/home` shell. The goal is to keep one persistent
surface and one visual language rather than opening a separate popup window for
every feature.

The local Quickshell installation is **0.3.1**. Quickshell is pre-1.0, so API
names and behavior should be checked against the installed version when a
feature is implemented.

## Executive recommendation

Use **one `PanelWindow` per screen**, with a stable transparent layer surface and
a single inner island that owns both the compact bar and expanded content:

```text
ShellRoot
├── shared services (audio, power, updates)
└── Variants { model: Quickshell.screens }
    └── Bar / DynamicIsland (one PanelWindow per screen)
        ├── compact island: power, tasks, tray, workspaces, status
        ├── expanded background/shape
        └── Loader: exactly one active mode
            ├── power
            ├── workspace preview
            ├── tray menu
            ├── launcher
            ├── audio preview
            └── update list
```

The important part is not Synoptik's exact shape math. It is the ownership
model:

1. The layer surface stays alive.
2. The compact bar and expanded content are siblings inside that surface.
3. A controller owns one active mode and its anchor.
4. Mode content reports `implicitWidth`/`implicitHeight`.
5. The wrapper animates one geometry/progress state and clips the content.
6. The surface's input `Region` contains only the visible island and expanded
   card.
7. Expanded content overlays the desktop while `exclusiveZone` remains the
   compact bar's zone, so tiled windows do not move during every interaction.

Do not port `UnifiedSurface.qml` wholesale. It is currently about 2,300 lines
of highly customized geometry, frame styles, OSD exceptions, auto-hide, and
shape paths. Reuse its concepts in a smaller home-specific controller.

## What Synoptik actually does

### Active implementation versus legacy implementation

The active path is:

- [`shell.qml`](file:///home/koss/code/Synoptik/shell.qml):473-535 — creates one
  `UnifiedSurface` for each `Quickshell.screens` entry and loads the selected
  drawer component.
- [`components/UnifiedSurface.qml`](file:///home/koss/code/Synoptik/components/UnifiedSurface.qml)
  — owns the layer surface, compact bar, expanded content, state, geometry,
  focus, masking, animation, and shape rendering.

[`components/bars/PanelWindows.qml`](file:///home/koss/code/Synoptik/components/bars/PanelWindows.qml)
is an older duplicate implementation. It is useful for understanding the
simpler predecessor, but it is not the source of truth for current behavior.

Synoptik's README describes the intended design accurately: one persistent bar
that “expands, shifts, and adapts its physical footprint” instead of scattering
separate bars, docks, and menus.

### 1. The persistent surface

`UnifiedSurface.qml:15-20` is a `PanelWindow`, not a `PopupWindow`. It is sized to
the screen (`implicitHeight`/`implicitWidth` are based on screen dimensions plus
shadow padding), made transparent, and positioned for the configured bar
orientation (`:307-318`). The expanded content is therefore another item in the
same layer-shell surface.

The relevant internal split is:

- `barContent` (`:2103-2179`) — the persistent compact bar and its module cards.
- `contentContainer` (`:2181` onward) — the active expanded view, clipped and
  positioned below/alongside the bar.
- Shape items in the large middle section — draw the visual union of the bar and
  panel, including flush corners and frame-style variants.

This is the core pattern to reproduce in `home/`: **do not put a
`PanelWindow` inside each mode component**. Mode components should be ordinary
`Item`/`FocusScope` content rendered by the existing per-screen surface.

### 2. State is split into intent and presentation

Synoptik has two layers of state:

- `Config.qml:189-204` contains a flag for each feature (`showPower`,
  `showAudio`, `showAppLauncher`, `showWorkspacePreview`, and so on). These are
  the feature intents and are also used by buttons/IPC handlers.
- `UnifiedSurface.qml:515` has `activeView`, the one view actually rendered on
  this screen. `updateActiveView()` (`:575-613`) resolves the flags using a
  priority order and gates interactive content to the focused monitor.

`closeOthers(except)` (`:625-649`) manually clears all competing flags. Every
flag change is observed in `Connections` (`:651-735`) so the active view is
re-anchored and the surface is opened or closed.

The useful invariant is “one active view.” The home shell can make this much
simpler with a single controller property instead of a growing collection of
booleans:

```qml
property string activeMode: "compact"
property string openReason: "none" // hover, click, shortcut, submenu
property var anchorItem: null
property bool pinned: false
```

A future `ModeController`/`DynamicIsland` should expose functions such as
`showTransient(mode, anchor)`, `open(mode, anchor)`, `toggle(mode, anchor)`, and
`close()`. The mode components should emit requests rather than mutate several
unrelated flags. Persistent settings may remain in a configuration singleton;
volatile open/hover state should stay local to each screen instance.

### 3. Content measurement drives island size

The active drawer is loaded in `shell.qml:485-518`. On load, the item is saved as
`activeDrawerItem` and receives focus if it supports `forceActiveFocus()`.
`UnifiedSurface.rawChildWidth`/`rawChildHeight` (`:178-214`) first use the
loaded item's implicit dimensions and then use conservative fallbacks for
views whose content has not measured yet.

The wrapper then derives `targetWidth`/`targetHeight` (`:261-278`) and animated
`currentWidth`/`currentHeight` (`:280-305`). This avoids hard-coding the surface
to the largest possible panel and lets a launcher, power card, or workspace
preview have different footprints.

Home mode components should therefore:

- have an explicit `implicitWidth` and `implicitHeight`;
- use a maximum width/height so an unexpectedly long list cannot cover the whole
  monitor;
- use `Loader` for expensive content such as screenshots or a large launcher;
- keep the shell wrapper responsible for clipping and animation;
- avoid changing the outer layer surface's exclusive zone during normal opens.

### 4. Anchoring and bounds

`refreshPopoutPos()` (`:517-568`) maps a mode name to a registered trigger
button. `setPopoutPos()` (`:615-623`) maps the trigger's center into
`mainContainer` coordinates. `staticLeft`/`staticRight` (`:474-513`) clamp the
expanded span to the usable screen/island bounds.

The island style adds a second footprint calculation:

- `islandContentWidth`/`islandContentHeight` and target dimensions
  (`:400-433`) account for left modules, active-window content, right modules,
  and minimum spacing.
- `animatedIslandWidth`/`animatedIslandHeight` make the compact island itself
  resize independently.
- `islandX`/`islandY` (`:437-438`) center the footprint.
- The active window card is clamped between the left and right cards
  (`:2133-2156`) instead of being allowed to overlap them.

For the first home implementation, use a simpler top-bar geometry: center the
normal island, anchor expanded content to the trigger's x-coordinate, and clamp
it to the monitor edges. Add side/bottom-bar orientation only after the top-bar
case is stable.

### 5. Input, focus, and dismissal

The surface uses several mechanisms together:

- A `Region` mask (`:368-372`) includes only `barContent`, visible expanded
  content, and an auto-hide edge trigger. Transparent pixels outside that region
  do not become a giant click-blocking surface.
- The expanded content is clipped and consumes input (`:2181` onward).
- A `MouseArea` over `mainContainer` (`:764-771`) closes on outside click.
- `WlrLayershell.keyboardFocus` is `OnDemand` while open and `None` while closed
  (`:374-379`).
- `HyprlandFocusGrab` (`:390-397`) closes the mode when focus is cleared outside
  the shell surface.
- `Escape` is handled with a `Shortcut` (`:381-388`).

A home implementation should retain this separation:

- compact bar: non-focusable;
- launcher/tray menu/click-open panel: `OnDemand` keyboard focus and a
  `FocusScope` that explicitly calls `forceActiveFocus()`;
- hover-only preview: no keyboard grab unless keyboard navigation is intentionally
  supported;
- all persistent modes: outside-click and Escape dismissal;
- mask: compact and expanded visible geometry only.

`opacity: 0` is not click-through. Disable input and remove a closed mode from
the mask after its exit transition.

### 6. Hover peek is a separate transient state

Synoptik does not simply set `isOpen` whenever a pointer enters a button.
`isPeeking`, `peekTargetItem`, and `peekProgress` (`:22-90`) are separate from
full panel state. `startPeek(item)` refuses to peek when a panel is already open,
records the target, maps its position, and animates a small protruding shape.
The peek span is based on the target's size plus padding (`:71-78`).

This distinction is useful for home:

- **peek:** small visual affordance or a compact hover card, temporary, no mode
  ownership;
- **hover preview:** a real but transient mode, with a delayed close timer;
- **open:** click/shortcut-owned mode that remains while the pointer leaves the
  original button.

Do not rely on `HoverHandler.hovered` alone for a large panel. Expanding the
surface can move the pointer out of the original item, and a gap between the
button and card causes flicker. Keep a stable hover bridge in the wrapper and
use a short close timer while moving between the trigger and expanded content.

### 7. Animation and visual continuity

Synoptik's basic open/close transition is a `progress` property:

- open: 480 ms `OutBack`, overshoot `0.55` (`:773-787`);
- close: 280 ms `InBack`, overshoot `1.2` (`:789-798`);
- width/height target changes: 350 ms `OutBack` (`:261-278`);
- content opacity: about 180 ms (`:2315-2320`).

It also applies nonlinear height squish (`Math.pow(closeFactor, 1.8)`), width
correction, rounded “wings,” and a 16 ms spring-like matrix deformation based on
content velocity (`:2224-2313`). The deformation is decorative, not required
for the architecture. Start with one `progress` and ordinary `Behavior`
animations; add squish only after input and bounds are correct.

### 8. What Synoptik does not solve

- It does not perform compositor-level collision detection against arbitrary
  application windows. Its “avoidance” is clamping to the screen/frame/island
  geometry and reshaping corners when a panel is flush.
- It has a large amount of manual `Config.show*` clearing. Home should retain the
  one-mode invariant without copying all of that boilerplate.
- It uses view-level processes for some features. Home should keep persistent
  polling and command execution in shared services where possible.
- Workspace previews are expensive: they compose `ScreencopyView` captures of
  toplevels rather than reading one built-in workspace screenshot.

## Mapping the pattern onto `home/`

### Current home structure

The current home shell is already a good starting point:

- [`home/shell.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/shell.qml):22-30
  creates one `Bar` per `Quickshell.screens` entry.
- [`home/Bar.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/Bar.qml):8-36
  is currently the per-screen `PanelWindow`; it is only `BarMetrics.height` tall
  and has a compact `exclusiveZone`.
- `PowerActions`, `AudioActions`, and `UpdateService` are already shared from
  `shell.qml` rather than recreated by every monitor.
- `BarPill`, `PillButton`, `IconButton`, and `BarMetrics` provide reusable
  visuals and timing.

The requested modes are the initial scope. Existing clock, Bluetooth, VRR,
task-list, and status indicators can remain compact-only while the island is
built. Synoptik features not requested here—calendar, notifications, wallpaper,
network, battery, control center, settings, mirror, recorder, and system
monitor—should be deferred, but if they are added later they should use the same
mode `Loader` rather than introducing another surface.

The main architectural change is to turn `Bar.qml` into a sufficiently large,
transparent host for the island. Its current `implicitHeight: BarMetrics.height`
(`Bar.qml:18-19`) cannot contain a panel below the bar. The host can occupy the
screen or a bounded expanded canvas while keeping:

```qml
exclusiveZone: BarMetrics.height + BarMetrics.margin
```

That preserves the current compact layout reservation. Set the top layer
explicitly, use a `Region` mask, and make keyboard focus conditional on the
active mode. Do not create a second `PanelWindow` for each feature.

The current Hyprland startup still launches **Waybar**
(`config/mise/templates/hypr/hyprland.lua:53-55`), while the quickshell home tree
is linked separately. Before calling the island a Waybar replacement, change
startup and remove the duplicate top-layer bar; running both will create
competing status bars, input regions, and exclusive zones.

### Suggested component boundary

A future layout could be organized as:

```text
home/
├── shell.qml                    # shared services and screen variants
├── Bar.qml                      # per-screen PanelWindow host
├── components/
│   ├── DynamicIsland.qml        # state, geometry, mask, focus, transitions
│   ├── IslandBackground.qml     # compact/expanded unified shape
│   └── ModeLoader.qml            # optional mode registry
├── modes/
│   ├── PowerMode.qml
│   ├── WorkspacePreviewMode.qml
│   ├── TrayMenuMode.qml
│   ├── LauncherMode.qml
│   ├── AudioPreviewMode.qml
│   └── UpdatesMode.qml
└── services/
    ├── AudioService.qml         # state + writes, in addition to pavucontrol
    ├── PowerActions.qml
    └── UpdateService.qml        # structured update model
```

This is a target shape, not a request to create all these files immediately.
The first vertical slice can keep the current compact widgets inside `Bar.qml`
and add only `DynamicIsland` plus `PowerMode`.

### Proposed controller state

Keep state per `Bar`/monitor, with shared data services in `ShellRoot`:

```qml
property string activeMode: "compact"
property string openReason: "none" // hover, click, shortcut, submenu
property var anchorItem: null
property var hoverTarget: null
property bool modePinned: false
property real progress: 0
property real targetWidth: 0
property real targetHeight: 0
```

Recommended transitions:

1. `compact -> hover mode`: set an anchor and start a short open animation;
   mark the mode transient.
2. `hover mode -> compact`: start a delayed close when neither the trigger nor
   the expanded content is hovered.
3. `compact -> click/shortcut mode`: mark the mode pinned, request keyboard
   focus if needed, and enable `HyprlandFocusGrab`.
4. `mode A -> mode B`: close/reuse the same wrapper and replace the `Loader`
   source; never open a second top-level surface.
5. Any outside click, Escape, or mode action: clear the mode and animate the
   same island back to compact.

Mode content should communicate through signals such as `closeRequested`,
`openMode(mode)`, and `actionTriggered()`. It should not know the pixel geometry
of the `PanelWindow`.

## Feature-by-feature design

### 1. Revisited power menu — first implementation target

**Current home:** [`PowerMenu.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/widgets/PowerMenu.qml):6-83
uses a local `HoverHandler`; its `actionDrawer` only changes width while the
bar remains 30 px high. It exposes lock, logout, reboot, and shutdown through
[`PowerActions.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/services/PowerActions.qml).

**Synoptik reference:** [`Power.qml`](file:///home/koss/code/Synoptik/components/Power.qml)
contains a larger “POWER OPTIONS” card with Lock, Suspend, Log Out, Reboot, and
Power Off, followed by a power-profile selector. It is a normal loaded view with
implicit dimensions, not a separate popup window.

**Home mapping:**

- Keep the home icon as the compact trigger.
- On hover, expand the same island into a modest action row or preview card;
  do not execute anything from hover.
- On click, pin/open `power` mode so the pointer can leave the icon while the
  card remains usable.
- Use a data-driven action model in `PowerMode.qml` and keep commands in
  `PowerActions.qml`.
- Target parity with Synoptik is Lock, Suspend, Log Out, Reboot, and Power Off,
  plus a power-profile selector in the pinned/full power mode. Add suspend and
  `powerprofilesctl` only as explicit service methods; do not put command
  strings in the visual delegate. If the first slice omits profiles, record
  that as a deliberate follow-up rather than losing the requirement.
- Consider confirmation for reboot/poweroff. Synoptik executes these directly,
  but an accidental expanded-menu click is a poor failure mode.
- Close the island before lock/logout/poweroff. Lock should hand off to
  `hyprlock`; the shell should not wait for the command.

This is the best first slice because it exercises hover, a persistent mode,
implicit measurement, a small number of actions, outside-click dismissal, and
no expensive data capture.

### 2. Workspace switcher and future hover previews

**Current home:** [`WorkspaceSwitcher.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/widgets/WorkspaceSwitcher.qml):7-63
is a centered `BarPill`, filters `Hyprland.workspaces.values` to the current
monitor, sorts by ID, animates active width, and calls `workspace.activate()`.

**Recommended island behavior:**

- Preserve the current monitor-local model and active styling in compact mode.
- Track the hovered workspace object/ID, not just a global “workspace preview
  open” boolean.
- Hovering a workspace enters transient `workspacePreview` mode anchored to that
  workspace segment. The preview should remain open while the pointer is over
  either the segment or the island card.
- Clicking the workspace activates it. Decide separately whether the preview
  closes immediately or remains open for selecting a window.
- A keyboard-driven overview can use the same mode with `GlobalShortcut` and
  `HyprlandFocusGrab`; a hover-only preview should not steal focus.

The existing [`hyprland.md`](file:///home/koss/code/dotfiles/config/quickshell/hyprland.md)
records the important capture design: there is no direct
`workspace.screenshot`. A preview is composed from `workspace.toplevels` and
`toplevel.wayland` handles with `ScreencopyView`, using each window's geometry.
For the first version:

1. Render workspace number, occupancy, icons, and titles even without capture.
2. Capture a still frame only for the hovered workspace.
3. Enable live captures only while the preview card is hovered, if needed.
4. Refresh on relevant `Hyprland.rawEvent` events rather than polling every
   frame.
5. Click a thumbnail to focus its toplevel; click the workspace card to call
   `workspace.activate()`.

Do not start with live thumbnails for every window on every workspace. This mode
is an excellent fit for the island, but it should be the second or third slice
after geometry is proven.

### 3. System tray and shell-native context menus

**Current home:** [`SystemTray.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/widgets/SystemTray.qml):19-47
renders `SystemTray.items`. Left/ordinary activation calls `modelData.activate()`;
right-click calls `modelData.display(root.hostWindow, ...)`, which delegates to a
native/platform menu.

Quickshell 0.3.1 exposes the DBus menu behind a tray item as `SystemTrayItem.menu`.
The relevant local types are:

- `QsMenuOpener.menu` and `.children` — exposes menu entries to QML;
- `QsMenuEntry` — `text`, `icon`, `enabled`, `isSeparator`, `hasChildren`,
  checkbox/radio state, and `triggered()`;
- `QsMenuAnchor` — asks the platform to render a menu and is therefore **not**
  the desired shell-native renderer here;
- `DBusMenuItem.menuHandle` — useful for opening a child menu when implementing
  nested submenu levels.

The intended replacement is a `TrayMenuMode` rendered by the island:

1. Right-click a tray item and pass its `SystemTrayItem` plus anchor to the
   island controller.
2. Use `QsMenuOpener` with `trayItem.menu`.
3. Render separators, disabled entries, icons, checkboxes, radio entries, and
   submenu arrows with home theme components.
4. Call `entry.triggered()` for leaf actions.
5. For `hasChildren`, push a child menu handle onto a small submenu stack or
   replace the same island content with the child level; do not create a native
   popup for every submenu.
6. Handle asynchronous DBus menu updates and close the mode if the tray item is
   unregistered.

The exact child-handle wiring should be verified with one real tray application
on Quickshell 0.3.1. `QsMenuEntry` inherits the menu-handle interface in the
installed QML type information, but this is worth a small runtime probe before
building a general recursive renderer.

Preserve the rest of the StatusNotifier affordances while replacing only the
renderer: `onlyMenu` items should open the shell menu instead of attempting
activation; middle/secondary activation should call `secondaryActivate()` when
provided; and wheel events can be forwarded through `scroll(delta, horizontal)`.
The current `SystemTray.qml` only accepts left/right buttons, so these are
explicit follow-up interactions rather than assumed existing behavior.

The context-menu controller should own the selected item; `SystemTray.qml`
should only emit a request instead of calculating native menu coordinates.

### 4. Launcher

**Synoptik reference:** [`AppLauncher.qml`](file:///home/koss/code/Synoptik/components/AppLauncher.qml)
uses `DesktopEntries.applications`, ignores `noDisplay` entries, filters by name,
generic name, description, categories, and keywords, sorts pinned entries ahead
of others, resolves icons with `Quickshell.iconPath`, and launches with
`app.execute()`. Its search `TextInput` is focused when opened; Up/Down changes
the `ListView` selection, Enter launches, and Escape closes (`:93-210` and the
search/list section later in the file). It is loaded into `UnifiedSurface`, so
its search card/list is already the shape requested here.

**Home mapping:**

- Add a `LauncherMode` with a search field at the top and a bounded `ListView`
  below it.
- Use `DesktopEntries.applications.values` first; avoid Synoptik's Python icon
  indexer until `Quickshell.iconPath` proves insufficient.
- Start with case-insensitive name/generic-name/comment matching. Add categories,
  keywords, and pins as follow-up behavior.
- Use a `FocusScope` and explicitly focus the `TextInput` after the mode is
  loaded. Handle Up/Down, Enter, and Escape in the mode.
- Enter should call `DesktopEntry.execute()` and close the island.
- Open from a global Hyprland shortcut or a compact button. The current
  Hyprland template binds `SUPER+R` to external Rofi
  (`config/mise/templates/hypr/hyprland.lua:46-47,166-174`); migrate that binding
  only when the Quickshell launcher is ready.
- Do not run Rofi and the shell launcher on the same key during migration.

The launcher is a strong demonstration of why one island is preferable: the
search bar, results, keyboard focus, and result list all grow from the compact
trigger while keeping one dismissal/focus owner.

### 5. Volume and microphone input

**Current home:** `StatusArea.qml:79-92` opens `pavucontrol` on click and reads
only `Pipewire.defaultAudioSink` for the compact icon. `AudioActions.qml` is
currently just the external `pavucontrol` launcher.

**Synoptik reference:** [`Audio.qml`](file:///home/koss/code/Synoptik/components/Audio.qml)
keeps output and input state (`systemVolume`, `isMuted`, `inputVolume`,
`isInputMuted`), renders two direct-drag sliders, toggles mute, enumerates sink
and source devices, and listens to `pactl subscribe` (`:16-31` and
`:627-715`).

Quickshell 0.3.1's Pipewire API already exposes `defaultAudioSink` and
`defaultAudioSource`, each with an `audio` interface containing writable
`volume` and `muted` properties. This may cover the basic preview without
parsing every `wpctl` output. Synoptik's `wpctl`/`pactl` approach remains a useful
fallback for device lists and event behavior.

**Proposed behavior:**

- Hovering the volume/status control enters transient `audioPreview` mode.
- The island shows two compact rows: playback level/mute and microphone
  input/mute. Keep the rows short enough to be useful without becoming a full
  settings panel.
- A click on the compact control still calls
  `audioActions.openControl()` (`pavucontrol`) rather than turning the hover
  preview into a second full audio application.
- Dragging a preview slider writes to the default sink/source; mute buttons
  toggle those same objects. Debounce writes if using `wpctl` processes.
- Move live audio state into one shared `AudioService` in `shell.qml`, rather
  than starting one `pactl subscribe` process for every screen or every view.
- Add device selection only after the two-level preview feels right. It can
  become a pinned `audio` mode later.

This should be a hover preview with no focus grab. A click that launches
`pavucontrol` should close the transient island or leave it in compact mode.

### 6. System updates

**Current home:** [`UpdateService.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/services/UpdateService.qml):8-40
runs `dnf check-update -q | wc -l` at startup and hourly, exposes only a string
count, and opens `kitty --hold --detach dnf check-update` on click. `StatusArea`
renders that count at `:59-74`.

**Proposed behavior:**

- Hovering the update indicator enters transient `updatesPreview` mode.
- The island shows a bounded, scrollable list of package name, available
  version, and repository (when available), plus loading/error/stale-data
  states.
- Keep the current terminal action as the click behavior initially. A separate
  “open details” row can make that action explicit.
- Extend the shared `UpdateService` to expose structured updates, not just a
  count. Parse `dnf check-update` output in one place and retain the last good
  result while a refresh is running.
- Treat `dnf check-update` exit code 100 as “updates available,” not a generic
  failure. Avoid the current shell pipeline hiding the command's exit status.
- Refresh on the existing hourly timer and optionally refresh once when the
  hover card opens if the last result is stale. Do not run `dnf` repeatedly as
  the pointer moves across the bar.
- Keep applying updates out of the shell for now; use the terminal or a future
  explicit privileged workflow.

This is another cheap hover mode once the general island controller exists, but
it needs a service/model change before the UI can show a useful list.

## Shared Quickshell constraints and pitfalls

### Layer surface and exclusive zone

Use the existing `Variants { model: Quickshell.screens }` architecture. The
surface should be a top layer with a stable full-screen or expanded canvas, but
its exclusive zone should normally remain `BarMetrics.height + BarMetrics.margin`.
Animating the exclusive zone would make tiled windows reflow every time a card
opens. If a future mode intentionally wants a reflowing dashboard, make that a
separate explicit behavior.

### Masking and transparent input

A full-screen transparent `PanelWindow` without a mask can intercept clicks over
the desktop. Union the compact island, expanded content, and any intentional
hover bridge in a `Region`. Remove the expanded item from the region after the
close transition, not merely after setting opacity to zero.

### Focus ownership

Use `GlobalShortcut` for global opening; a local `Shortcut` only works while the
shell already has focus. Because `Bar` is instantiated once per screen, register
each global shortcut exactly once at `ShellRoot` and route its request to the
`Bar` whose screen matches `Hyprland.focusedMonitor`; do not register duplicate
`appid:name` pairs in every `Variants` delegate. Use a `FocusScope` for the
launcher and keyboard menus, call `forceActiveFocus()` after `Loader.onLoaded`,
and use `HyprlandFocusGrab` for outside-click/touch dismissal. Do not use
exclusive keyboard focus for ordinary hover previews.

The focused-monitor rule used by Synoptik (`screen.name` compared with
`Hyprland.focusedMonitor.name`) is a good default for global launcher and
shortcut modes. Hover-triggered modes should remain on the monitor whose item
was hovered.

### `Loader` and implicit sizes

A mode's implicit size may be zero while its `Loader` is still constructing it.
Provide conservative fallback dimensions and update the target dimensions after
`Loader.onLoaded`/implicit-size changes. Keep the loaded mode anchored to the
wrapper, not to the original button, so the pointer can enter the expanded
content without losing it.

### Hover versus click semantics

Every trigger should distinguish:

- pointer hover, which may be transient;
- click, which may pin a mode or launch an external application;
- keyboard shortcut, which should normally pin/focus a mode.

Do not close a click-open launcher or tray menu merely because the pointer left
the original trigger. Conversely, do not leave a hover update card open forever
if the pointer leaves both the trigger and card.

### Preview cost

Workspace/window previews should use still captures by default and live captures
only while needed. The current `hyprland.md` documents the required
`toplevel-export` capability and the fact that a whole-workspace preview is a
composition of window captures.

### Runtime/version checks

The installed API can be inspected locally under
`/usr/lib64/qt6/qml/Quickshell` and is currently Quickshell 0.3.1. In particular,
verify the runtime behavior of nested DBus menus, `Region` unions, `PopupAnchor`
coordinates, and Pipewire writes before relying on them in a generalized
component.

## Suggested implementation order

1. **Resolve ownership:** decide when Quickshell replaces Waybar, update startup,
   and ensure only one top-layer bar/exclusive zone is running.
2. **Build the shell:** refactor `Bar.qml` into a stable per-screen host with a
   masked compact island, a `progress` animation, and an empty mode `Loader`.
3. **Power vertical slice:** implement the expanded power mode and migrate the
   current `PowerMenu` hover behavior into the controller. Verify outside click,
   Escape, monitor focus, and destructive-action handling.
4. **Launcher:** add the focused search/list mode and replace the `SUPER+R` Rofi
   binding once it is reliable.
5. **Audio preview:** add shared input/output state and hover sliders while
   retaining click-to-`pavucontrol`.
6. **Updates preview:** extend `UpdateService` to a structured model and render a
   hover list.
7. **Workspace preview:** add one-workspace hover cards and still captures, then
   consider live previews/keyboard overview.
8. **Tray menu:** implement the custom DBus menu renderer, nested submenu stack,
   and tray-item lifecycle handling.
9. **Cleanup:** remove duplicate compact widgets and obsolete Waybar/Rofi paths
   only after each replacement has been verified.

### First vertical-slice acceptance criteria

- No mode creates a second `PanelWindow`.
- With no mode active, the current compact bar looks and behaves as before.
- Hovering power expands the same island; moving from the trigger into the card
  does not flicker.
- Clicking an action invokes the shared service and returns the island to a
  safe state.
- Escape and outside click close the mode.
- Transparent areas remain click-through.
- Only the focused/triggering monitor receives a global mode.
- Expanded content does not change the tiled layout's exclusive zone.
- The surface can be reloaded safely while services continue to be shared.

## Roadmap-document status

The prompt refers to `workspace-switcher.md`, `context-menus.md`, and
`launcher.md`, but those files are not present in the current checkout. Their
stated requirements were treated as inputs to this note:

- workspace switcher: eventual hover previews while swapping;
- context menus: replace native tray right-click menus with shell-native QML
  menus;
- launcher: a Synoptik-style search bar and result list.

The existing [`hyprland.md`](file:///home/koss/code/dotfiles/config/quickshell/hyprland.md)
is the current API/behavior reference for `GlobalShortcut`,
`HyprlandFocusGrab`, `ScreencopyView`, monitor-aware launchers, and workspace
previews. Those feature-specific documents can be added later without changing
the island architecture described here.

### Footnote from notifications
When the shared drawer/dynamic-island host is implemented, move notifications into it instead of maintaining a second `PanelWindow` with its own masking, routing, and slide behavior.

## Source references

### Local source

- [`Synoptik/README.md`](file:///home/koss/code/Synoptik/README.md)
- [`Synoptik/components/UnifiedSurface.qml`](file:///home/koss/code/Synoptik/components/UnifiedSurface.qml)
- [`Synoptik/shell.qml`](file:///home/koss/code/Synoptik/shell.qml)
- [`Synoptik/components/AppLauncher.qml`](file:///home/koss/code/Synoptik/components/AppLauncher.qml)
- [`Synoptik/components/Audio.qml`](file:///home/koss/code/Synoptik/components/Audio.qml)
- [`Synoptik/components/Power.qml`](file:///home/koss/code/Synoptik/components/Power.qml)
- [`Synoptik/components/WorkspacePreview.qml`](file:///home/koss/code/Synoptik/components/WorkspacePreview.qml)
- [`dotfiles/config/quickshell/home/Bar.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/Bar.qml)
- [`dotfiles/config/quickshell/home/shell.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/shell.qml)
- [`dotfiles/config/quickshell/home/widgets/PowerMenu.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/widgets/PowerMenu.qml)
- [`dotfiles/config/quickshell/home/widgets/WorkspaceSwitcher.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/widgets/WorkspaceSwitcher.qml)
- [`dotfiles/config/quickshell/home/widgets/SystemTray.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/widgets/SystemTray.qml)
- [`dotfiles/config/quickshell/home/widgets/StatusArea.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/widgets/StatusArea.qml)
- [`dotfiles/config/quickshell/home/services/UpdateService.qml`](file:///home/koss/code/dotfiles/config/quickshell/home/services/UpdateService.qml)
- [`dotfiles/config/quickshell/hyprland.md`](file:///home/koss/code/dotfiles/config/quickshell/hyprland.md)

### Quickshell 0.3.1 references

- [PanelWindow](https://quickshell.org/docs/v0.3.1/types/Quickshell/PanelWindow/)
- [PopupWindow](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupWindow/)
- [PopupAnchor](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupAnchor/)
- [HyprlandFocusGrab](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandFocusGrab/)
- [GlobalShortcut](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/GlobalShortcut/)
- [ScreencopyView](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/ScreencopyView/)
- [QsMenuEntry](https://quickshell.org/docs/v0.3.1/types/Quickshell/QsMenuEntry/)
- [QsMenuOpener](https://quickshell.org/docs/v0.3.1/types/Quickshell/QsMenuOpener/)
- [QsMenuAnchor](https://quickshell.org/docs/v0.3.1/types/Quickshell/QsMenuAnchor/)
- [SystemTrayItem](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.SystemTray/SystemTrayItem/)
- [DBusMenu module](https://quickshell.org/docs/v0.3.1/types/Quickshell.DBusMenu/)
