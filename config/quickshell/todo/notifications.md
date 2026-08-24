# Native Quickshell notifications — implementation specification

> **Status:** decision-complete; implementation is intentionally deferred.
>
> This document is the handoff for a fresh implementation session. It records
> the current repository/runtime state, every resolved product decision, the
> migration boundary, and the required verification. Do not reopen these choices
> or silently substitute different behavior. Ask before changing the scope or a
> specified behavior.
>
> Delete this file only after the implementation, migration, and full live test
> checklist are complete.

## Goal

Replace Dunst's popup UI and notification-server role with one native
Quickshell `NotificationServer`, an interactive top-right popup stack, and a
bell pill in the existing Quickshell bar.

Existing producers such as `notify-send`, libnotify applications, and
`grimblast` must continue using the freedesktop notification D-Bus interface
unchanged.

This is an **active notification stack**, not a notification history. A card
exists only while its native notification remains active. Expired,
application-closed, dismissed, and cleared notifications are removed.

## Fixed scope

Implement:

- summary and body;
- low, normal, and critical urgency styling;
- supplied application icon names/paths and urgency-specific fallback icons;
- freedesktop body markup and clickable hyperlinks;
- regular notification images;
- native default and non-default actions, including requested action icons;
- positive, default, and persistent timeout behavior;
- per-card expansion and close controls;
- replacement notifications;
- one shared, scrollable popup stack;
- hover-paused expiry;
- clear all;
- Quickshell hot-reload retention;
- focused-monitor routing;
- fullscreen suppression and queuing;
- a bar pill that toggles and routes the active stack;
- the tracked Dunst-to-Quickshell repository migration.

Do **not** implement:

- notification history or grouping;
- disk persistence;
- do-not-disturb mode;
- inline replies;
- inline images embedded in body markup;
- progress/value hints;
- middle-click or swipe dismissal;
- keyboard focus or keyboard controls;
- lock-screen integration;
- an IPC bridge for the old Waybar controls;
- application-specific notification rules.

`persistenceSupported` must remain false. In-process survival across a
Quickshell QML reload does not count as notification persistence.

## Current repository state

The Quickshell configuration is under `config/quickshell/home` (this document
is under `config/quickshell/todo`). Relevant files are:

- `home/shell.qml`
  - has one `ShellRoot`;
  - refreshes Hyprland toplevels;
  - creates `Launcher {}`;
  - creates one `Bar` per `Quickshell.screens` through `Variants`;
  - has no notification service or popup.
- `home/Bar.qml`
  - creates one top bar `PanelWindow` per screen;
  - the left side contains power, task list, and system tray;
  - the right side contains `StatusArea`.
- `home/widgets/StatusArea.qml`
  - currently orders the right-side pills as VRR/updates, volume, Bluetooth,
    then clock;
  - the notification bell must be inserted immediately before the clock.
- `home/theme/Theme.qml` and
  `config/mise/templates/quickshell/home/theme/Theme.qml`
  - expose the Rose Pine palette used below.
- `home/config/BarMetrics.qml`
  - `height = 30`, `margin = 7`, `gap = 9`,
    `animationDuration = 300`, and `iconButtonWidth = 34`;
  - `primaryOutput = "DP-1"`, but notification routing must not use it as the
    no-focus fallback.

The existing QML already imports
`Quickshell.Services.SystemTray`. That service is unrelated to desktop
notifications. The replacement must import:

```qml
import Quickshell.Services.Notifications
```

### Current Dunst footprint

Dunst is home-linux-only and currently appears in:

- `config/dunst/dunstrc` — an empty tracked file;
- `config/mise/mise.home-linux.toml` — links `config/dunst` and renders the
  Dunst theme drop-in;
- `config/mise/templates/dunst/dunstrc.d/theme.conf` — Dunst's Rose Pine
  presentation;
- `config/mise/templates/hypr/hyprland.lua` — starts
  `dunst & hyprpaper & waybar`;
- `config/waybar/config.jsonc` — contains a commented-out notification module
  and a stale `custom/notification` declaration using `notify-history` and
  `dunstctl close-all`.

`bin/grimblast` and `desktops/grimblast.desktop` are notification producers,
not Dunst integrations. Do not change them.

### Current live system at clarification time

- Quickshell: `0.3.1` from Fedora COPR;
- running shell: `qs -p quickshell/home`;
- `org.freedesktop.Notifications` owner: Dunst;
- StatusNotifier host/watcher owner: Quickshell;
- installed Dunst package: `dunst-1.13.2-1.fc43.x86_64`;
- installed libnotify package: `libnotify-0.8.8-1.fc43`;
- Dunst D-Bus activation file:
  `/usr/share/dbus-1/services/org.knopwob.dunst.service`;
- Dunst user unit: `/usr/lib/systemd/user/dunst.service`.

Only one process can own `org.freedesktop.Notifications`. The native server may
wait silently while Dunst owns the name.

## Quickshell API contract

Create exactly one `NotificationServer` outside all per-screen `Variants`.
There must never be one server per monitor.

Advertise only implemented capabilities:

```qml
NotificationServer {
  keepOnReload: true
  bodySupported: true
  bodyMarkupSupported: true
  bodyHyperlinksSupported: true
  bodyImagesSupported: false
  actionsSupported: true
  actionIconsSupported: true
  imageSupported: true
  inlineReplySupported: false
  persistenceSupported: false
}
```

For each incoming notification, set `notification.tracked = true`. Relevant
native API includes:

- `id`, `lastGeneration`, `summary`, `body`, `appName`, `appIcon`, and `image`;
- `urgency`, `expireTimeout`, `resident`, `transient`, `actions`, and `hints`;
- change signals for replacement updates;
- `dismiss()` and `expire()`;
- `NotificationAction.identifier`, `.text`, and `.invoke()`;
- `NotificationUrgency.Low`, `.Normal`, and `.Critical`.

`trackedNotifications`/reload re-emission can be used to rebuild active cards.
`lastGeneration` identifies notifications retained from the prior QML
generation.

Installed API metadata is available at:

```text
/usr/lib64/qt6/qml/Quickshell/Services/Notifications/quickshell-service-notifications.qmltypes
```

Version-matched documentation:

- <https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/NotificationServer/>
- <https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/Notification/>
- <https://specifications.freedesktop.org/notification/latest-single/>

## Required state model

The exact QML file split is an implementation detail, but the design must have:

1. one global native notification server/controller;
2. one record per active native notification;
3. one shared popup window, never duplicated across monitors;
4. one card delegate per record;
5. one bell control in every bar, all controlling the same global stack.

A record needs enough state to implement at least:

- native notification reference/ID;
- expanded/collapsed state;
- active versus queued timing state;
- configured total timeout;
- remaining time while hover-paused;
- whether its timer has started;
- replacement updates;
- native close cleanup.

Use a single source of truth. The bar pills, clear-all control, popup window,
and timers must not maintain divergent copies of the active list.

## Notification lifecycle

### New notification

1. Track it immediately.
2. Append it to the end of the active list; newest cards belong at the bottom.
3. Resolve the currently focused Hyprland monitor. If there is no valid focused
   monitor, use the first screen reported by Quickshell.
4. Move the one shared stack, including all existing cards, to that screen.
5. If fullscreen suppression is not active, collapse the new card, start its
   timer when applicable, reveal the stack, and request bottom scrolling.
6. If fullscreen suppression is active and no manual visibility override is
   active, queue the card without starting its timer and keep the stack hidden.

There is no urgency exception during fullscreen: low, normal, and critical
notifications all queue.

### Replacement

A valid `replaces_id` updates the existing card in place; it does not create a
second card and does not reorder the card in the list.

On replacement:

- update all mirrored content and action properties;
- collapse the card;
- preserve its position in the list;
- treat the update as a new arrival for monitor routing and stack visibility;
- outside suppressed fullscreen, move to current focus, reveal, and restart the
  full timeout;
- during suppressed fullscreen, stop the previous timer, update the card, and
  queue the reset timeout until fullscreen exits or the user manually reveals
  the stack;
- animate changed height/content, but do not fake a separate new card.

### Native closure and explicit dismissal

- Application-requested closure removes the record/card.
- The per-card close button calls `dismiss()` and removes the record/card.
- Clear all calls `dismiss()` for every active or queued native notification.
- An elapsed timer calls `expire()`, reports the Expired close reason, and
  removes the record/card.
- Invoked actions close with `dismiss()` unless `resident` is true.
- Do not keep invisible closed records as history.
- When the final card finishes its exit animation, hide the stack immediately.

## Timeout semantics

The freedesktop timeout is in milliseconds.

| Native `expireTimeout` | Required behavior |
| --- | --- |
| `> 0` | Honor the supplied timeout exactly for every urgency. |
| `0` | Never expire automatically. |
| `-1` + low | Use 10 seconds. |
| `-1` + normal | Use 10 seconds. |
| `-1` + critical | Never expire automatically. |

Treat other negative server-default values consistently with `-1` if one is
encountered.

### Timer rules

- A queued notification has not been displayed and its timer has not started.
- Showing a queued notification—because fullscreen ended or because the user
  manually revealed the stack—starts its full timeout.
- Hovering anywhere over the visible stack, including its header, cards, gaps,
  or scrollbar, pauses **all started finite timers**.
- Leaving the stack resumes every paused timer with its actual remaining time;
  do not restart full timeouts.
- A notification received while the hovered stack is visible starts in the
  paused state.
- Manually hiding the stack outside fullscreen does not pause started timers.
- Automatically hiding existing cards because fullscreen began does not pause
  their already-started timers.
- Replacements follow the replacement rules above.
- Persistent (`0`, or default critical) records have no expiry timer.

Do not rely on a QML `Timer` restart as a substitute for remaining-time
accounting.

## Fullscreen behavior

Fullscreen suppression applies when a visible toplevel on the relevant
monitor's active workspace has **any** Hyprland fullscreen flag greater than
zero. This deliberately includes maximized/fullscreen mode `1`, not only
exclusive fullscreen values greater than `1`. Account for an active special
workspace when determining the visible workspace.

### Entering fullscreen

When the stack's screen enters this state:

- hide the entire stack, including critical cards;
- keep already-started timers running;
- queue all later new notifications without starting their timers;
- queue replacement reset timers as described above.

### Exiting fullscreen

When suppression ends:

- resolve the currently focused monitor again;
- move the shared stack there;
- if that target is not itself suppressed, reveal every remaining active and
  queued card;
- start each queued card's full timer;
- restore the stack even when no notification arrived during fullscreen, as
  long as at least one active card remains;
- keep the stack hidden if no cards remain.

If the current focused target is still fullscreen-suppressed, preserve the
queue until it can be shown or the user manually overrides suppression.

### Manual fullscreen override

The bar pill may reveal the stack over fullscreen content.

- A manual reveal starts every queued timer immediately.
- While the stack remains visible, fullscreen is treated as ineffective for
  later arrivals and replacements: they display and start/reset normally.
- The override lasts only while the stack remains visible.
- Once the pill hides the stack again while fullscreen is still active, later
  arrivals/replacements queue again.

There is no lock-state integration. Let compositor/Hyprlock layer ordering
obscure notifications while locked.

## Monitor routing

There is one shared stack and one global visible/hidden state.

- New notifications and replacements route to `Hyprland.focusedMonitor`.
- If focused-monitor mapping fails, use the first `Quickshell.screens` entry.
- Routing moves the entire active stack, not just the newest card.
- Merely changing monitor focus does not move the stack.
- A later arrival/replacement moves it.
- Do not show duplicates on multiple screens.

The bell exists on every bar:

- if hidden and cards exist, clicking a bell moves the stack to that bell's
  monitor and shows it;
- if visible on that monitor, clicking its bell hides it;
- if visible on another monitor, clicking a different bell first routes to that
  clicked monitor and then applies the global toggle, so the result is hidden;
- clicking with no active or queued cards is a no-op;
- a later arrival still reroutes to focused monitor and reveals unless
  fullscreen suppression requires queuing.

## Stack placement and scrolling

Use one top-right popup/panel surface that does not reserve compositor space and
does not block pointer input outside its actual visible content.

All dimensions are QML logical pixels:

- width: `400`;
- right screen margin: `7`;
- top begins below the bar: bar top margin `7` + bar height `30` + gap `9`, so
  stack content starts at y=`46`;
- bottom screen margin: `7`;
- maximum height: the available region between y=`46` and the bottom margin;
- card gap: `9`;
- card border: `2`;
- card radius: `10`;
- card content padding: `10`.

Keep the clear-all header fixed. Only the card list scrolls.

- Append newest notifications at the bottom.
- If not hovered, a new arrival scrolls to the bottom so it is visible.
- If hovered/scrolled up, preserve the current position and remember that a new
  card arrived.
- On pointer leave, animate to the bottom.
- Clip overflow.
- Show a slim themed vertical scrollbar only while the stack is hovered and the
  list actually overflows.
- A fully expanded card may exceed the viewport; render its complete content
  and let the outer notification list scroll through it. Do not add a nested
  body scroller or clamp expanded body lines.

## Fixed header and clear all

Whenever at least one active or queued card exists and the stack is visible,
show a fixed compact header containing only a clear-all icon aligned to the
right.

- No `Notifications` title.
- No text label.
- Clear all includes queued cards.
- Clear all sends native user dismissals; it is not UI-only removal.
- Hovering the header pauses timers as part of whole-stack hover.

## Bar pill

Add a `34`px-wide, bell-only pill to `StatusArea` on every monitor. The final
right-side order is:

1. VRR/updates;
2. volume;
3. Bluetooth;
4. notifications bell;
5. clock.

Do not display an active count in the pill or any tooltip.

Color states:

- no active/queued cards: `Theme.muted`;
- cards exist and stack hidden: `Theme.accent`;
- stack visible: `Theme.active`.

Use the existing shell hover treatment and pointer cursor. The pill takes no
keyboard focus.

## Card presentation

### Shared geometry and typography

- collapsed/minimum card height: `64`;
- leading app icon slot: `32 × 32`;
- summary size: `14px`;
- body size: `12px`;
- expanded regular-image maximum height: `180`;
- collapsed body preview: exactly one elided line;
- full body: visible when expanded.

### Neutral urgency palette

Every card uses `Theme.surface` as its background and `Theme.text` for normal
body/metadata text. Urgency changes the border, leading icon treatment, and
summary accent only:

| Urgency | Accent |
| --- | --- |
| Low | `Theme.muted` |
| Normal | `Theme.rose` |
| Critical | `Theme.love` |

### Leading icon and regular image

Resolve the supplied `appIcon` name/path directly. Do not add a
`DesktopEntries`/`appName` heuristic. Use urgency fallback icons when the
supplied icon is empty or cannot resolve:

| Urgency | Fallback icon |
| --- | --- |
| Low | `dialog-information` |
| Normal | `dialog-warning` |
| Critical | `dialog-error` |

If `notification.image` exists:

- collapsed mode uses a cropped `32 × 32` preview in place of the app icon;
- expanded mode restores the resolved app/fallback icon in the leading slot;
- expanded content shows the regular image proportionally scaled within the
  card and capped at `180`px high;
- do not cache the image to disk;
- do not treat body `<img>` markup as supported inline images.

### Collapsed content

Show:

- leading app/fallback icon, or regular-image preview;
- summary;
- one elided body line when a body exists;
- expand chevron when extra content exists;
- close button.

Do not show the app name in collapsed mode.

Show the expand chevron only when expansion has something additional to reveal:

- truncated body content;
- application name metadata;
- regular image;
- one or more visible non-default actions.

### Expanded content

Expansion reveals:

- application name as the only extra metadata;
- complete rich body;
- full regular image;
- non-default action buttons.

Do not show an urgency label or countdown.

The chevron is the expand/collapse control. Main-card clicks are reserved for
the default action behavior below.

### Markup and hyperlinks

- Render the summary as normal text.
- Render body markup with Qt's native styled/rich text support; a custom HTML
  parser is not required.
- Advertise body markup and body hyperlinks.
- Do not advertise inline body images.
- Open clicked hyperlinks with `Qt.openUrlExternally`.
- Opening a hyperlink leaves the notification active and does not invoke its
  default action.
- Ensure link, action, chevron, and close hit targets do not fall through to the
  main-card default action.

### Actions

- Advertise actions and action icons.
- Preserve sender order for non-default actions.
- Render non-default actions as compact labeled buttons that wrap onto more
  rows when needed.
- When `hasActionIcons` requests icons, render the requested action icon with
  its label; fall back to a text button if the icon cannot resolve.
- Do not duplicate the `default` action in the expanded button list.
- If a default action exists, clicking the main card invokes it.
- If no default action exists, clicking the main card does nothing.
- After any default or non-default native action is invoked, dismiss the
  notification unless `resident` is true.
- A resident notification remains active after action invocation until its
  timeout, app-requested closure, clear all, or explicit close.

### Dismissal and input

- The visible close button is the only per-card dismissal gesture.
- No middle-click dismissal.
- No swipe dismissal.
- No click-anywhere dismissal.
- Pointer input only; popup cards must not claim keyboard focus.

## Animations

Use `300ms` (`BarMetrics.animationDuration`) animations:

- cards enter from the right edge;
- cards leave toward the right edge;
- existing cards move smoothly when another card is inserted/removed;
- card height animates during expansion, collapse, content replacement, and
  removal;
- the entire fixed header + card stack slides from/to the right when the bell
  reveals or hides it.

A replacement updates in place and uses content/height transitions rather than
a fake remove/reinsert animation.

## Hot reload

Set `keepOnReload: true`.

When Quickshell re-emits retained native notifications into a new QML
generation:

- track them again;
- rebuild cards collapsed;
- reset each finite timeout to its full configured duration;
- treat the rebuilt cards as arrivals for current focused-monitor routing and
  visibility;
- if fullscreen suppression applies, queue them instead;
- do not preserve expansion, prior screen, prior stack visibility, prior
  remaining timer duration, or scroll position;
- do not write any reload state to disk.

A full Quickshell process exit/restart is not required to retain notifications.
Only in-process QML hot reload is supported.

## Repository migration

After the native implementation works:

1. In `config/mise/templates/hypr/hyprland.lua`:
   - remove Dunst from startup;
   - start Quickshell in its own `hl.exec_cmd("qs -p quickshell/home")` call;
   - keep `hyprpaper & waybar` in a separate existing-style command.
2. In `config/mise/mise.home-linux.toml`:
   - remove the `~/.config/dunst` deployment;
   - remove the rendered Dunst theme deployment.
3. Delete:
   - `config/dunst/dunstrc`;
   - `config/mise/templates/dunst/dunstrc.d/theme.conf`;
   - empty Dunst directories left behind in the repository.
4. In `config/waybar/config.jsonc`:
   - remove the commented `custom/notification` module entry;
   - remove the entire stale `custom/notification` declaration;
   - do not replace `notify-history` or `dunstctl` with an IPC bridge.
5. Leave notification producers unchanged.
6. Apply the dotfiles/bootstrap changes needed to remove stale deployed Dunst
   config links from `~/.config/dunst`.
7. Stop the live Dunst process for testing and normal use.

### Deliberate live-system boundary

Do **not** uninstall the Fedora Dunst package and do **not** add a systemd mask.
The selected policy is “stop only.” Keep libnotify/`notify-send` installed.

This deliberately leaves a caveat: Dunst's package-provided D-Bus activation
and static user unit remain available. Dunst can reclaim
`org.freedesktop.Notifications` if a notification arrives while Quickshell is
not running. Do not silently “fix” that caveat by uninstalling or masking it.

Delete this specification file as the final repository cleanup only after all
implementation and verification work passes.

## Implementation constraints

- Read `config/quickshell/AGENTS.md` before implementation/testing.
- Do not launch a second `qs` process while the current
  `qs -p quickshell/home` instance is running. Quickshell already watches and
  reloads this configuration.
- Keep the `NotificationServer` outside screen `Variants`.
- Keep one shared popup surface; do not render one copy per monitor.
- Ensure the popup surface has no exclusive zone and an input mask limited to
  visible UI.
- It must be possible to reveal the surface over fullscreen through the bell
  without giving it keyboard focus.
- Reuse the existing Rose Pine `Theme` singleton and `BarMetrics`; do not add a
  second palette.
- Do not modify `grimblast` or other notification producers to target
  Quickshell directly.
- Preserve unrelated working-copy changes and use `jj`, not `git`.

Optional presentation references (not behavior specifications):

- `~/code/shell/services/Notifs.qml`
- `~/code/shell/services/NotifData.qml`
- `~/code/shell/modules/notifications/Content.qml`
- `~/code/shell/modules/notifications/Notification.qml`

That shell is much larger and must not be copied wholesale. In particular, do
not import its persistence, DND, image cache, grouped history, sidebar,
fullscreen policy, or plugin system.

## Verification plan

Run full live verification. Static checks alone are insufficient.

### Preflight and ownership

Confirm monitor geometry and current processes:

```sh
hyprctl monitors -j | jq '[.[] | {name, x, y, width, height, scale, transform}]'
pgrep -a 'qs|quickshell|dunst|waybar'
busctl --user list | rg 'org.freedesktop.Notifications|StatusNotifier'
```

After the native implementation has loaded, stop the live Dunst process without
uninstalling/masking it, then verify Quickshell acquires the name. Do not start a
second Quickshell process.

Expected ownership after migration:

- `org.freedesktop.Notifications` — the existing `qs` process;
- StatusNotifier host/watcher — the same Quickshell process;
- no running Dunst process.

Inspect the existing instance's logs for QML/runtime errors throughout testing.

### Core notification matrix

Basic summary/body:

```sh
notify-send "Test" test
```

Urgencies and fallback styling:

```sh
notify-send -u low "Low" "Low urgency"
notify-send -u normal "Normal" "Normal urgency"
notify-send -u critical "Critical" "Critical persists by default"
```

App icons and fallback:

```sh
notify-send -n dialog-information "Named icon" "Uses supplied app icon"
notify-send -n definitely-not-a-real-icon "Fallback" "Uses urgency fallback"
notify-send -u critical -n definitely-not-a-real-icon "Critical fallback" "Uses dialog-error"
```

Positive timeout, server default, and protocol-persistent timeout:

```sh
notify-send -t 3000 "Three seconds" "Must expire after 3s of unpaused display"
notify-send "Ten seconds" "Low/normal default is 10s"
notify-send -t 0 "Persistent" "Must remain until explicitly closed"
```

Verify:

- positive timeout is interpreted as milliseconds;
- `-t 0` persists;
- default low/normal lasts 10 seconds;
- default critical persists;
- expiry reports Expired rather than Dismissed;
- hovering beyond the timeout pauses all cards and leaving resumes remaining
  time rather than restarting it.

### Markup, links, and images

Use a body containing bold/italic markup and an `<a href>` link. Verify markup,
pointer hit testing, external opening, and that link activation leaves the card
active.

Create a known local image and pass it as the standard regular notification
image hint, for example:

```sh
mkdir -p /tmp/quickshell-preview
magick -size 640x360 gradient:'#d7827e-#286983' /tmp/quickshell-preview/notification.png
notify-send \
  -h string:image-path:/tmp/quickshell-preview/notification.png \
  "Image" "Collapsed preview and expanded full image"
```

Verify collapsed image replacement, expanded app-icon restoration, aspect
ratio, 180px cap, and missing-image fallback. Also verify that inline body
images are not advertised.

### Actions

Run action-bearing notifications in a background shell so stdout can be
checked:

```sh
notify-send \
  -A default=Open \
  -A later=Later \
  "Actions" "Card invokes Open; expanded button invokes Later" \
  >/tmp/quickshell-preview/action-result.txt &
```

Verify:

- main-card click invokes `default`;
- default is absent from expanded buttons;
- non-default actions wrap and invoke in sender order;
- action result appears in the capture file;
- non-resident action invocation dismisses;
- `boolean:resident:true` remains after invocation;
- requested action icons render with text fallback when unresolved;
- close, chevron, links, and buttons never accidentally invoke the default
  action.

### Replacement

```sh
id="$(notify-send -p -t 0 "Replace me" "First body")"
notify-send -r "$id" -t 3000 "Replaced" "Updated body"
```

Verify one in-place card, stable list position, collapsed state, current-focus
routing, reveal, content/height transition, and reset timer. Repeat while
fullscreen-suppressed and verify the replacement waits with a fresh queued
timeout.

### Stack, scrolling, and clear all

Create enough persistent notifications to overflow the available height:

```sh
for index in $(seq 1 20); do
  notify-send -t 0 "Notification $index" "Scrollable body $index"
done
```

Verify:

- newest is at the bottom;
- one stack only;
- y=46/right=7/bottom=7 bounds;
- fixed icon-only clear header;
- hover-only scrollbar;
- new arrival scrolls to bottom while idle;
- hovered/scrolled position is preserved until pointer leave;
- expanded oversized content uses the outer scroll area;
- clear all dismisses every active/queued notification and hides the stack.

### Bell and monitor routing

On both monitors, verify:

- bell placement before clock;
- 34px geometry;
- muted/accent/active colors;
- no count in the pill or tooltip;
- empty click no-op;
- hidden click moves to clicked monitor and shows;
- same-monitor visible click hides;
- different-monitor visible click moves then hides;
- a later notification reroutes the whole stack to focused monitor;
- focus change alone does not move it;
- no notification is duplicated.

### Fullscreen

Exercise a window with any Hyprland fullscreen/maximized flag greater than zero
and restore its prior state afterward.

Verify:

- entering fullscreen hides the whole stack;
- already-started timers continue invisibly;
- all urgency levels arriving while hidden queue without starting;
- leaving fullscreen restores remaining cards on current focus and starts full
  queued timers;
- a queued 3-second notification still gets a full 3 seconds after reveal even
  if fullscreen lasted longer;
- bell reveal over fullscreen shows all queued cards and starts their timers;
- later arrivals behave normally while that manual stack remains visible;
- hiding it again restores queuing for later arrivals;
- replacement while suppressed queues its reset timeout.

### Hot reload

Create active finite and persistent notifications, expand at least one, then
trigger the existing Quickshell instance's normal QML hot reload (for example by
touching a loaded QML file). Verify:

- no second `qs` process appears;
- the native notifications survive;
- cards rebuild collapsed;
- finite timers reset to full duration;
- screen routes to current focus;
- stack reveals unless fullscreen requires queuing;
- no duplicate cards or native close events occur.

### Native closure and producer compatibility

Use a printed notification ID and call `CloseNotification` from the sender side
to verify application-requested removal. Test close buttons and clear all for
Dismissed behavior.

Run the relevant `grimblast --notify` path and an error path. Existing producers
must work unchanged.

### Visual capture

Follow `config/quickshell/AGENTS.md`: capture the full virtual desktop, then
crop the bar/stack for the relevant monitor. Save screenshots for at least:

- low/normal/critical cards;
- collapsed and expanded markup/image/action cards;
- overflowing stack and scrollbar;
- bell hidden/visible states;
- stack on each monitor;
- fullscreen manual reveal.

Restore the pointer, window fullscreen state, and any other desktop state after
interactive tests.

## Acceptance checklist

Implementation is complete only when all are true:

- [ ] One Quickshell `NotificationServer` owns
      `org.freedesktop.Notifications` after Dunst is stopped.
- [ ] Capabilities exactly match implemented markup/image/action support.
- [ ] Normal `notify-send`, grimblast notifications, and application producers
      work unchanged.
- [ ] Timeout, hover, queue, replacement, resident-action, close-reason, and
      reload behavior match this document.
- [ ] One shared stack routes correctly and never duplicates across monitors.
- [ ] Fullscreen/maximized suppression and manual override pass live tests.
- [ ] Bar bell, clear all, expansion, links, images, actions, scrolling, and
      animations pass interaction tests.
- [ ] Dunst repository config/startup and stale Waybar controls are removed.
- [ ] Quickshell has one separate Hyprland autostart command.
- [ ] Live Dunst is stopped but its package/unit/activation remain installed,
      with the documented caveat accepted.
- [ ] QML/static checks and live logs contain no new errors.
- [ ] Visual captures match the specified geometry and Rose Pine states.
- [ ] This completed todo file is deleted as the final cleanup.
