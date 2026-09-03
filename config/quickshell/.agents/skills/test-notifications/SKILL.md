---
name: test-notifications
description: >
  Repeatable, non-invasive verification for the native Quickshell notification
  server. Use the bundled Bash runner to exercise display, expiry, dismissal,
  replacement, markup, images, actions, urgency styling, and notification
  drawer interactions without starting a second Quickshell process.
---

# Test native notifications

Run this skill from `config/quickshell` while the existing Quickshell session is
running:

```sh
bash .agents/skills/test-notifications/test-notifications.sh --case all
```

The runner refuses to send tests unless `org.freedesktop.Notifications` is
owned by the existing `qs` process and no Dunst process is running. It never
starts Quickshell, uses `dunstctl`, or writes notification state to disk.
Screenshots and D-Bus monitor output are
written below `/tmp/quickshell-preview/notifications-tests` by default; override
this with `--output-dir` or `QUICKSHELL_NOTIFICATION_TEST_DIR`.

The interaction cases require `hyprctl`, `jq`, ImageMagick, Python 3, and
writable `/dev/uinput`. Pointer movement uses the Hyprland Lua dispatcher and
clicks use a short-lived virtual mouse device at the already-positioned pointer.
The runner saves the pointer position before testing and restores it after every
interaction and again in its exit trap, including failure paths. Screenshot
geometry probes are stored as `.notification-geometry.png` under the selected
output directory and overwritten on each probe.

## Cases and expected results

| Case | What it does | Expected result |
| --- | --- | --- |
| `preflight` | Inspects the existing shell, bus owner, and Dunst process | One existing `qs` owns `org.freedesktop.Notifications`; Dunst is absent; no second shell is started. |
| `basic` | Sends a normal summary/body notification and captures the desktop | One card grows down from the focused monitor's notification bell with the supplied summary and body. The capture file is non-empty. |
| `expiry` | Sends a `1200ms` notification while monitoring `NotificationClosed` | The same notification closes automatically and emits close reason `1` (`Expired`), proving the timeout is interpreted as milliseconds. |
| `persistent-close` | Sends `-t 0`, then calls native `CloseNotification` | The card remains until the explicit native close and emits reason `3` (`CloseRequested`). |
| `replacement` | Sends a persistent notification, then replaces its ID with new content | The capture shows the updated content in one card, in the original list position; no second card is created. |
| `markup` | Sends bold, italic, and hyperlink body markup | The capture shows rich text and a visible link. The script does not activate the link, so no browser is opened. |
| `image` | Sends a generated regular `image-path` hint | The capture shows the image as the collapsed leading preview instead of the app icon. The image is created under the output directory. |
| `actions` | Expands an action card, invokes non-default and default actions, and checks resident behavior | Expansion increases the screenshot-detected attached-card height; non-resident actions emit `ActionInvoked` and close with reason `2`; resident actions emit `ActionInvoked` but remain until native close. |
| `urgencies` | Sends low, normal, and critical persistent cards | The capture shows all three cards, with low/muted, normal/rose, and critical/love styling; newest cards are appended at the bottom. |
| `hover` | Moves the pointer into a card, waits past its timeout, then moves outside | No close signal arrives while hovered; leaving resumes the timer and produces close reason `1` (`Expired`). |
| `clear-all` | Sends three persistent cards and clicks the drawer header's clear-all button | Each test ID emits close reason `2` (`Dismissed`) through the native notification objects and the attached card disappears. The case refuses to run over an existing visible stack. |
| `routing` | Focuses a second monitor and sends a persistent notification | Screenshot probing finds the attached notification card on the focused monitor and not on the previously focused monitor. It skips safely when only one monitor is active or the candidate monitor is already fullscreen. |
| `fullscreen` | Enters fullscreen on the active window, sends a persistent notification, then leaves fullscreen | The notification remains suppressed while fullscreen is active and the same queued card is revealed after fullscreen ends. The original fullscreen state is restored on failure. |
| `reload` | Sends a persistent card and triggers the existing shell's normal QML file watcher | The same `qs` PID reloads, no close signal is emitted, and the card remains visible. A temporary trailing newline is restored byte-for-byte (including its timestamp); no second shell is started. |
| `interactions` | Runs `hover`, `actions`, `clear-all`, `routing`, `fullscreen`, and `reload` | All available interaction checks pass; monitor routing/fullscreen checks may report their documented safe skips. |
| `all` | Runs every case above | All available checks pass and every notification ID created by the runner is closed by the case or exit cleanup. |

The surface assertions are black-box desktop observations. The runner combines
Hyprland monitor geometry with screenshots to locate the bar-colored card joined
to the island, then uses `gdbus monitor` for native close/action signals. It does
not add test-only QML properties or IPC hooks.

## Safety and cleanup

Every notification ID created by the runner is closed during its case or in
its exit trap. It does not use a notification-history command or a UI
clear-all action when a visible unknown stack is present. Before interaction
cases, a visible pre-existing attached notification card causes a refusal rather
than risking a click on an unrelated card.

The fullscreen case changes only the active window and toggles it back. The
reload case temporarily appends a newline to the existing
`home/widgets/notifications/NotificationService.qml`, waits for the normal
reload event, then restores the original bytes and mtime. If the runner is
interrupted during either operation, its exit trap performs the restoration.

## Manual follow-up

The automated suite verifies automatic fullscreen reveal after leaving
fullscreen. If the desktop is safe to interact with, manually verify the
notification bell's explicit fullscreen override as well as visual details
that are not reliable black-box assertions (font rendering, exact colors,
scrollbar appearance, and hover animation). A full Quickshell process restart
is not part of this skill; hot reload uses the existing process's normal QML
watcher and `qs log --pid <pid>`.
