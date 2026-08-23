# Replacing Dunst with native Quickshell notifications

## Recommendation

Yes: Quickshell has a native notification module, separate from its system-tray
module:

```qml
import Quickshell.Services.Notifications
```

`NotificationServer` implements the freedesktop notification service and owns
`org.freedesktop.Notifications`. It receives the same `notify-send`/
libnotify traffic that Dunst receives. However, it is not a ready-made popup
theme: it supplies the D-Bus server and notification objects, while the popup,
stack, animations, history, and controls must be written in QML.

The recommended replacement is therefore:

1. Keep existing notification producers such as `notify-send`.
2. Add one `NotificationServer` at the `ShellRoot` level.
3. Add a small QML notification model and top-right popup stack.
4. Remove Dunst's startup, configuration, and D-Bus activation.
5. Keep the first version intentionally smaller than a complete notification
   center: no disk history, DND system, image cache, or inline replies until
   those features are needed.

The current machine has Quickshell 0.3.1 installed. Quickshell is pre-1.0, so
this API should be checked against the installed version when implementation
starts.

## Current Dunst footprint

The repository's Dunst usage is limited to the `home-linux` environment. An
audit found these direct references:

| Purpose | File | Current behavior |
| --- | --- | --- |
| Base configuration | `config/dunst/dunstrc` | An empty tracked file. |
| Theme deployment | `config/mise/mise.home-linux.toml:10,15` | Links `config/dunst` into `~/.config/dunst` and renders `templates/dunst/dunstrc.d/theme.conf` into the Dunst drop-in directory. |
| Startup | `config/mise/templates/hypr/hyprland.lua:54` | Starts `dunst` together with `hyprpaper` and `waybar` on `hyprland.start`. |
| Waybar control | `config/waybar/config.jsonc:125-132` | Declares a notification module whose right click runs `dunstctl close-all`; the module is currently commented out at line 66. Its `notify-history` command is not present in this repository. |
| Notification producer | `bin/grimblast:10,135,145,211` | Uses `notify-send`, including a 3-second timeout for normal messages and critical urgency for errors. |
| Desktop producer | `desktops/grimblast.desktop:5` | Always runs `grimblast --notify copysave area`. |

There is no Dunst package declaration in mise. Dunst and libnotify are external
system dependencies.

The current Quickshell entry point is only `ShellRoot { Bar {} }` in
`config/quickshell/home/shell.qml`. `Bar.qml` imports `SystemTray` and creates
one bar `PanelWindow` per screen, but imports no notification module and has no
notification model, popup, history, or dismissal UI. The repository documents
`qs -p quickshell/home` as a manual launch path; no tracked Quickshell startup
line was found in the Hyprland template.

### What the Dunst theme currently provides

`config/mise/templates/dunst/dunstrc.d/theme.conf` configures the visual
presentation, not application-specific notification behavior:

- 400px width, 5x5 offset, 10px padding, 3px frame, and 3px gap;
- 380px progress bars and 2px corner radii;
- the templated font and Rose Pine icon theme;
- recursive icon lookup;
- Rose Pine colors for low, normal, and critical urgency;
- default icons `dialog-information`, `dialog-warning`, and `dialog-error`;
- Pango-formatted summary/body output.

Timeouts, history persistence, rules, keybindings, and actions are not
customized in the repository; Dunst defaults apply. The native implementation
will need to reproduce the visual choices explicitly in QML, but it does not
need to preserve any repository-specific Dunst rules.

### What does not need to change

`grimblast` is notification-daemon agnostic. Its `notify-send` calls use the
freedesktop D-Bus interface, not a Dunst-specific API. They should continue to
work unchanged after Quickshell owns that interface. The replacement should
therefore support at least:

- summary and plain-text body;
- low/normal/critical urgency;
- application icon names and a fallback icon;
- the `-t 3000` timeout used by grimblast;
- critical screenshot errors.

## Quickshell's notification API

The relevant module is independent of the existing tray code:

```qml
import Quickshell
import Quickshell.Services.Notifications

ShellRoot {
  NotificationServer {
    id: notifications

    bodySupported: true
    bodyMarkupSupported: false
    bodyHyperlinksSupported: false
    bodyImagesSupported: false
    actionsSupported: false
    persistenceSupported: false

    onNotification: function (notification) {
      // Incoming notifications are not retained unless this is set.
      notification.tracked = true
      // Add a wrapper/record to the popup model here.
    }
  }

  Bar {}
}
```

The server should live outside `Bar.qml`'s per-screen `Variants` block. A
server per monitor would create multiple notification owners and make routing
ambiguous.

### Important types and behavior

- `NotificationServer.trackedNotifications` is an object model of tracked
  notifications.
- `Notification` exposes `summary`, `body`, `appName`, `appIcon`, `image`,
  `urgency`, `actions`, `hints`, `resident`, and `expireTimeout`.
- `notification.dismiss()` sends a dismissed/closed notification event.
- `notification.expire()` sends an expired event.
- `NotificationAction.invoke()` invokes an application-provided action.
- `NotificationUrgency.Low`, `.Normal`, and `.Critical` are available for
  urgency-aware styling.
- `keepOnReload` can retain notifications across a Quickshell reload, but the
  reload handler must track retained notifications again.
- `persistenceSupported` is a D-Bus capability flag; `NotificationServer` does
  not provide a disk-backed history by itself.
- The server does not draw anything. `PanelWindow`/`PopupWindow`, a list view,
  cards, timers, and dismissal interactions are application code.

`expireTimeout` deserves an explicit integration test with
`notify-send -t 5000`. The reference shell treats the value as a Qt timer
interval, and versions/documentation have differed on timeout units. Do not
assume Dunst's timeout behavior is automatically reproduced; have the QML
record start a timer and call `expire()` or hide the popup as appropriate.

### System tray is a different service

The existing code in `config/quickshell/home/Bar.qml` uses:

```qml
import Quickshell.Services.SystemTray
// model: SystemTray.items
```

`Quickshell.Services.SystemTray` is a StatusNotifier host for tray items and
menus (`org.kde.StatusNotifierWatcher`). It does not display or observe desktop
notifications. `Quickshell.Services.Notifications` is a separate D-Bus server
for `org.freedesktop.Notifications`. Both modules can be used by the same
Quickshell process, but the tray code cannot be extended to replace Dunst.

Only one process can own `org.freedesktop.Notifications`. While Dunst is
running, a `NotificationServer` cannot function as the replacement; it will
wait for the name to become available. The Dunst user service and its package's
D-Bus activation file must be disabled or removed as part of the migration, not
merely omitted from the Hyprland command. The current session audit showed
Dunst owning `org.freedesktop.Notifications` and Quickshell owning the
StatusNotifier host.

## Lessons from `~/code/shell`

`~/code/shell` is a useful reference for presentation, even though its
notification system is much larger than this repository needs.

### Reference architecture

The main path is:

```text
services/Notifs.qml
  -> NotificationServer and global NotifData records
modules/drawers/Drawers.qml
  -> modules/drawers/ContentWindow.qml
  -> modules/drawers/Panels.qml
  -> modules/notifications/Wrapper.qml
  -> modules/notifications/Content.qml
  -> modules/notifications/Notification.qml
```

`services/Notifs.qml` tracks each native notification, prepends new records to
a list, mirrors notification properties, and maps native actions to wrapper
functions. It also implements persistence at `${Paths.state}/notifs.json`, DND,
fullscreen behavior, image caching, and lifecycle locking. Those are useful
future features, but are not necessary for the first replacement here.

### Presentation worth copying

The popup implementation in `modules/notifications/Content.qml` and
`Notification.qml` provides the behavior worth adapting:

- a roughly 430px-wide panel anchored to the top-right;
- newest notifications inserted first, so the stack grows down from the corner;
- a clipped, vertically scrollable `ListView` when the stack is too tall;
- `move`/`displaced` transitions so existing cards slide into place;
- cards entering from the right and sliding out on removal;
- animated card height when content is expanded or removed;
- a compact card with an elided body preview;
- an expand control revealing the app name, full body, and action buttons;
- optional hover-paused expiry, middle-click close, and horizontal swipe
  dismissal;
- a separate sidebar that groups notifications by application and shows a
  configurable preview count.

The corner growth is a simple list-and-animation pattern, not a consequence of
an elaborate notification service. A small implementation can reproduce the
same feel with a global record list, one `PanelWindow`, a `ListView`, and a
single card component.

The reference shell uses shared Material 3 `Colours` and `Tokens` values. Its
normal, low, and critical cards use different surface/error colors while
keeping typography, spacing, radius, icon treatment, and animation consistent.
For this repository, the equivalent should reuse or centralize the existing
Rose Pine values in `Bar.qml` and the mise theme variables rather than copying
Caelestia's palette/plugin system.

### Complexity not to copy initially

The reference shell also contains behavior that would be disproportionate here:

- C++ configuration and animation plugins;
- JSON notification persistence and image-cache management;
- DND IPC and custom shortcuts;
- fullscreen and Hyprland-aware popup suppression;
- lock-screen/sidebar renderers and grouped history;
- lazy viewport tracking and lifecycle locks;
- a separate internal toast system unrelated to D-Bus notifications.

One multi-monitor detail is especially important: the reference shell creates a
drawer for each screen, while each drawer consumes the same global popup list.
That can show the same notification on every monitor. The new implementation
should deliberately choose one policy—initially the primary or focused monitor,
or explicit per-notification routing—instead of blindly duplicating that
structure.

## Proposed implementation shape

A maintainable first pass could use these conceptual pieces:

1. **Service/model in `home/shell.qml` or a sibling component.** Create one
   `NotificationServer`, wrap native notifications with only the state the UI
   needs (`expanded`, popup visibility, and timer state), and prepend new
   records. Track retained notifications after reload.
2. **Top-right stack.** Use one notification `PanelWindow` initially. Give it a
   width near Dunst's 400px, Rose Pine margins and spacing, a capped height, and
   a clipped `ListView`. Add explicit screen routing before creating one stack
   per monitor.
3. **Card.** Start collapsed: summary plus an elided body. Expand with an
   arrow or click to show the full body and actions. Add slide-in, displaced,
   height, and removal animations before adding gestures.
4. **Theme mapping.** Map urgency to Rose Pine surfaces and accents. Render
   summaries and bodies as plain text initially; only advertise and render
   markup, hyperlinks, images, progress hints, or inline replies once each is
   implemented and tested.
5. **Controls.** Put dismiss and clear-all in the Quickshell UI. The equivalent
   of `dunstctl close-all` is to call `dismiss()` on the tracked records. The
   currently disabled Waybar notification module should not remain the control
   path unless a separate IPC bridge is intentionally added.
6. **History later.** `trackedNotifications` can support an in-memory history
   view. Add JSON persistence only if history across restarts is desired; it is
   not supplied by the native server.

Suggested capability progression:

| Phase | Enable | Defer |
| --- | --- | --- |
| First popup | body, urgency, app icon, timeout, dismiss | markup, images, persistence, actions, inline replies |
| Interactive cards | native actions and buttons | inline replies and action icons |
| Notification center | in-memory history and grouping | disk persistence, DND, fullscreen policy |

### Dunst-to-QML visual mapping

| Dunst setting/behavior | Native implementation |
| --- | --- |
| `width = 400` and `offset = 5x5` | Set the stack width and top/right screen margins. |
| `padding`, `frame_width`, `gap_size`, and corner radii | Use card margins, a Rose Pine border, layout spacing, and rounded `Rectangle`s. |
| `font` and Pango `%s`/`%b` format | Use the existing shell font and separate summary/body `Text` items. Start with `Text.PlainText`; add markup only when deliberately supported. |
| `urgency_low`, `urgency_normal`, `urgency_critical` | Compare `notification.urgency` with `NotificationUrgency` values and select the corresponding Rose Pine surface, accent, and fallback icon. |
| `progress_bar_*` | Optional: read a supported value hint and draw a QML progress arc/bar. It is not needed for current `grimblast` messages. |
| Dunst timeout | Create a per-record `Timer` from `expireTimeout`, pause it while hovered if desired, and call `expire()`/remove the popup when it fires. Validate units first. |
| `dunstctl close-all` | Iterate the native records and call `dismiss()`; expose this from the native UI rather than Waybar. |

## Migration checklist

1. Build and test the QML service/model and popup UI without creating a second
   live Quickshell process. The current Quickshell configuration is launched
   with `qs -p quickshell/home`; its lifecycle should have exactly one owner.
2. Stop Dunst before testing `NotificationServer`. Confirm ownership with:

   ```sh
   busctl --user list | rg 'org.freedesktop.Notifications|StatusNotifier'
   ```

   After migration, `org.freedesktop.Notifications` should be owned by the
   Quickshell process, not Dunst.
3. Remove `dunst` from
   `config/mise/templates/hypr/hyprland.lua`, while preserving `hyprpaper` and
   `waybar`. If Quickshell is not started elsewhere, add its one existing
   startup mechanism rather than starting duplicate instances.
4. Disable/remove Dunst's user service and D-Bus auto-activation on the target
   machine. Package/service names are distro-specific; uninstalling Dunst is
   the least ambiguous way to prevent it reclaiming the notification name when
   Quickshell exits.
5. Remove the two Dunst deployment entries from
   `config/mise/mise.home-linux.toml`, then remove the empty
   `config/dunst/dunstrc` and the rendered theme template once the native theme
   is working.
6. Remove the stale disabled Waybar notification declaration and its Dunst
   command, or document an intentional IPC bridge. Do not carry
   `notify-history` forward as if it were an existing repository feature.
7. Test `notify-send` directly and through `grimblast`, including normal,
   critical, icon, timeout, multiple-notification, action, replacement, reload,
   and dismissal cases. Verify that notifications are not duplicated on
   multiple monitors and that a tall stack remains usable.

## References

### Local implementation

- Quickshell version: `qs --version` (currently 0.3.1)
- Installed notification API metadata:
  `/usr/lib64/qt6/qml/Quickshell/Services/Notifications/quickshell-service-notifications.qmltypes`
- Existing tray implementation:
  `config/quickshell/home/Bar.qml`
- Quickshell entry point:
  `config/quickshell/home/shell.qml`

### Quickshell and protocol documentation

- [Quickshell `NotificationServer`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/NotificationServer/)
- [Quickshell `Notification`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/Notification/)
- [Quickshell system-tray module](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.SystemTray/)
- [Freedesktop desktop notifications specification](https://specifications.freedesktop.org/notification/latest-single/)

### Reference shell files

- `~/code/shell/services/Notifs.qml`
- `~/code/shell/services/NotifData.qml`
- `~/code/shell/modules/notifications/Wrapper.qml`
- `~/code/shell/modules/notifications/Content.qml`
- `~/code/shell/modules/notifications/Notification.qml`
- `~/code/shell/modules/drawers/Panels.qml`
- `~/code/shell/modules/sidebar/NotifGroupList.qml`
- `~/code/shell/plugin/src/Caelestia/Config/notifsconfig.hpp`
- `~/code/shell/plugin/src/Caelestia/Config/tokens.hpp`
