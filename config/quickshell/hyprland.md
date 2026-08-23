# Quickshell and Hyprland

This document records the Hyprland-specific capabilities available to Quickshell
so that future UI work does not need to repeat the API research.

Quickshell is a QML/QtQuick desktop-shell toolkit, not a prebuilt Hyprland
overview application. The `Quickshell.Hyprland` module exposes Hyprland state,
IPC, and a few Hyprland protocols; the actual bar, popup, overview, or launcher
still needs to be built in QML.

The local installation is Quickshell 0.3.x. Quickshell is pre-1.0, so verify
APIs against the installed version when making substantial changes.

## Official references

- [Quickshell.Hyprland module](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/)
- [`Hyprland` singleton](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/Hyprland/)
- [`HyprlandMonitor`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandMonitor/)
- [`HyprlandWorkspace`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandWorkspace/)
- [`HyprlandToplevel`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandToplevel/)
- [`HyprlandEvent`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandEvent/)
- [`GlobalShortcut`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/GlobalShortcut/)
- [`HyprlandFocusGrab`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandFocusGrab/)
- [`HyprlandWindow`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandWindow/)
- [Quickshell `Toplevel`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/Toplevel/)
- [Quickshell `ScreencopyView`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/ScreencopyView/)
- [Quickshell `PanelWindow`](https://quickshell.org/docs/v0.3.1/types/Quickshell/PanelWindow/)
- [Quickshell `WlSessionLock`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlSessionLock/)
- [Hyprland IPC](https://wiki.hypr.land/IPC/)
- [Hyprland toplevel-export protocol](https://github.com/hyprwm/hyprland-protocols/blob/main/protocols/hyprland-toplevel-export-v1.xml)
- [Example: `quickshell-overview`](https://github.com/Shanu-Kumawat/quickshell-overview)

## Hyprland state models

Import the module with:

```qml
import Quickshell.Hyprland
```

The `Hyprland` singleton exposes live models and focus state:

```qml
Hyprland.monitors
Hyprland.workspaces
Hyprland.toplevels
Hyprland.focusedMonitor
Hyprland.focusedWorkspace
Hyprland.activeToplevel
```

It also provides:

- `Hyprland.monitorFor(screen)` to match a Quickshell screen to its Hyprland
  monitor.
- Monitor, workspace, and toplevel refresh methods:
  `refreshMonitors()`, `refreshWorkspaces()`, and `refreshToplevels()`.
- The Hyprland request and event socket paths.

### Monitors

`HyprlandMonitor` provides monitor ID, name, description, position, dimensions,
scale, focus state, and the active workspace. This supports per-monitor bars,
monitor-aware popups, and layouts that follow the focused monitor.

### Workspaces

`HyprlandWorkspace` provides:

- `id` and `name`, including named workspaces
- `active` and `focused`
- `urgent`
- `hasFullscreen`
- `monitor`
- `toplevels`, the windows belonging to the workspace
- `activate()`, which switches to the workspace

This is enough for occupancy indicators, named/special workspace controls,
urgent markers, fullscreen markers, workspace previews, and workspace grids.
Special-workspace state may require listening to the `activespecial` raw IPC
event because it is not always represented like an ordinary active workspace.

### Windows / toplevels

`HyprlandToplevel` provides read-only Hyprland metadata:

- `address`
- `title`
- `activated`
- `urgent`
- `workspace`
- `monitor`
- `wayland` and `handle`, which are handles for Wayland toplevel operations

The associated Wayland `Toplevel` provides application ID and additional window
state, plus operations such as:

- `activate()`
- `close()`
- maximize/minimize/fullscreen state
- `fullscreenOn(screen)`

This enables taskbars, Alt-Tab switchers, window pickers, window context menus,
urgent-window indicators, and click-to-focus/close controls.

## Hyprland IPC and events

Use `Hyprland.dispatch(request)` to send any Hyprland dispatcher request. This
is the escape hatch for actions that do not have a dedicated QML method, such
as focusing, moving windows, toggling floating/fullscreen, moving to a
workspace, or toggling a special workspace.

`Hyprland.usingLua` indicates whether the current Hyprland configuration uses
Lua dispatch syntax. Code that supports both configuration styles can select
the appropriate request, as the current bar does for workspace activation.

`Hyprland.rawEvent` emits events from Hyprland's event socket. The event has:

- `name`
- `data`
- `parse(argumentCount)`

Useful events include workspace changes, active-window changes, window open,
close, move, title changes, urgent changes, fullscreen changes, monitor changes,
and `activespecial`. Raw events are useful for event-driven previews and for
keeping derived models up to date without polling.

Do not retain the event object after the signal handler returns; copy the data
needed by the UI. If a property is stale after an event, call the corresponding
`refresh*()` method.

## Native Hyprland shortcuts

`GlobalShortcut` registers a shortcut through Hyprland's
`hyprland_global_shortcuts_v1` protocol. It exposes `pressed` state and
`onPressed` / `onReleased` signals.

Example:

```qml
GlobalShortcut {
  appid: "quickshell"
  name: "overview"
  description: "Toggle workspace overview"

  onPressed: overview.toggle()
}
```

Bind it in Hyprland with:

```ini
bind = SUPER, TAB, global, quickshell:overview
```

This is useful for opening an overview, launcher, dashboard, command palette,
or quick-settings UI without relying on a portal or shell window already having
keyboard focus. The `appid:name` pair must be unique.

## Hyprland popup focus grabs

`HyprlandFocusGrab` uses Hyprland's focus-grab protocol to keep keyboard focus
inside one or more listed Quickshell windows. It emits `cleared()` when the user
clicks or touches outside them.

This is useful for dismissible launchers, workspace-preview popups, dropdowns,
menus, and quick-settings panels:

```qml
HyprlandFocusGrab {
  active: popup.visible
  windows: [popup]

  onCleared: popup.visible = false
}
```

## Hyprland properties on Quickshell windows

`HyprlandWindow` is an attached object for windows created by Quickshell. It
currently exposes:

- `opacity`
- `visibleMask`, which can reduce rendering work for transparent/blurred UI

Example:

```qml
PanelWindow {
  HyprlandWindow.opacity: 0.95
}
```

This requires a sufficiently recent Hyprland version or `hyprland-surface-v1`
support.

## Workspace and window previews

A workspace preview is not a single built-in `workspace.screenshot` property.
It is composed from the windows in `workspace.toplevels`.

The usual implementation is:

1. Enumerate `Hyprland.workspaces`.
2. Enumerate each workspace's `toplevels`.
3. Use each toplevel's `.wayland` handle as the
   `ScreencopyView.captureSource`.
4. Arrange the captured windows using their Hyprland geometry, available in the
   toplevel's IPC object.
5. Use `workspace.activate()` to switch workspaces and the Wayland toplevel's
   `activate()` to focus a selected window.
6. Listen to `Hyprland.rawEvent` and refresh/re-capture after relevant changes.

`ScreencopyView` supports:

- Live capture with `live: true`
- A single frame with `live: false` and `captureFrame()`
- `hasContent`, `sourceSize`, `constraintSize`, and cursor control

The compositor must advertise a compatible toplevel-capture protocol, usually
`hyprland_toplevel_export_v1`. Check the current session with:

```sh
wayland-info | grep -E 'hyprland_toplevel_export|screencopy|image_capture'
```

The current session advertises `hyprland_toplevel_export_manager_v1`.

### Recommended bar interaction

For a preview popover on the workspace switcher:

- Anchor a `PopupWindow` below the hovered workspace pill.
- Show a card for each workspace on that monitor.
- Include window icons and titles even when screenshots are unavailable.
- Capture still frames only for the hovered workspace to keep resource usage low.
- Optionally use live previews while the pointer remains over the popover.
- Click a window thumbnail to focus it.
- Click the workspace card to activate it.
- Close on pointer leave or with `HyprlandFocusGrab`.

Live thumbnails for every window on every workspace are more expensive. An
event-driven still-frame mode is a better default for a hover preview; live mode
can be enabled only while the preview is visible. Applications may also stop
producing new frames while unfocused, in which case a preview can show the last
submitted frame.

## Features worth building

These are natural additions to the current bar:

- **Hover workspace preview:** workspace cards, window thumbnails, icons,
titles, and click-to-focus.
- **Full-screen overview / Exposé:** all monitors and workspaces in one overlay,
with keyboard navigation and click-to-focus.
- **Alt-Tab window switcher:** maintain an MRU list from active-window events and
show titles, icons, or live previews.
- **Window actions:** close, focus, fullscreen, maximize, minimize, move to a
workspace, or dispatch custom Hyprland commands from a context menu.
- **Special-workspace drawer:** show and toggle scratchpad/special workspaces,
including their windows and previews.
- **Workspace status indicators:** occupancy, named-workspace labels, urgent
windows, fullscreen state, and monitor association.
- **Active-window OSD:** show the application, title, workspace, monitor, and
state after focus changes.
- **Monitor-aware launcher/dashboard:** open on the focused monitor using
`focusedMonitor` and monitor geometry.
- **Native shortcut-driven command palette:** open via `GlobalShortcut`, manage
focus with `HyprlandFocusGrab`, and dispatch Hyprland actions.
- **Live window or monitor peek:** use `ScreencopyView` for a temporary preview
without changing workspace focus.

## Related Wayland capabilities

These are not exclusive to Hyprland, but work especially well with Hyprland's
layer-shell compositor:

- `PanelWindow` / layer-shell surfaces for bars, OSDs, overlays, and dashboards
- exclusive zones so bars reserve space from tiled windows
- overlay/top/background layers and keyboard-focus modes
- Wayland session lock via `WlSessionLock` for a custom lock screen
- idle inhibition for media players, presentations, or fullscreen UIs

## Boundaries

- Quickshell does not provide a ready-made Hyprland overview; it provides the
  state and rendering primitives to build one.
- There is no direct whole-workspace screenshot object. A thumbnail overview is
  normally a composition of per-window captures.
- Arbitrary Hyprland actions are possible through `dispatch()`, but not every
  action has a typed convenience API.
- The API can change between Quickshell releases because the project is still
  pre-1.0.
