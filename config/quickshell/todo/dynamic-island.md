# Dynamic island design

- **Status:** product and implementation design
- **Target:** `config/quickshell/home` on Quickshell 0.3.1
- **Scope:** replace the distributed top bar with one centered, icon-only island and one attached expansion surface

## Product statement

The bar is one compact rounded rectangle centered at the top of each monitor. It
floats a few pixels below the monitor edge and contains only icons—no clock text,
workspace numbers, device names, percentages, or update counts.

Hovering an icon grows one contextual card downward from that icon's position.
The card and the compact island read as one connected surface, not as a detached
tooltip or unrelated popup. The card may contain text, controls, lists, or
previews; the compact island remains icon-only.

Only one card can be expanded on a monitor at a time.

## Fixed design decisions

- There is exactly one compact background, not separate pills for groups or
  individual controls.
- The compact island is horizontally centered as a whole. It does not stretch
  across the monitor and does not have left-, center-, and right-aligned zones.
- Every compact item is an icon in a consistent 28 px layout slot. Standard
  triggers fill that slot; tray triggers preserve the 24 px input/anchor
  geometry required by `context-menus.md`.
- Small dots, rings, color changes, and progress arcs may communicate state.
  Text and numeric badges are not shown in the compact state.
- Hover is the primary way to reveal information. There is no separate tooltip
  competing with the attached card.
- The expanded card grows directly from the island with no neck, gap, or stub.
- The card aligns with the island edge nearest its triggering icon rather than
  centering beneath the icon.
- When the card would extend past the compact island, the island widens to meet
  every overhanging card edge so the two read as one continuous plane.
- Moving directly from one icon to another reuses the same card surface and
  morphs its attached edge; it does not close and reopen a second window.
- Hover cards do not take keyboard focus. Every pinned card requests on-demand
  focus so Escape and outside-focus dismissal work consistently; modes that
  type or navigate also move active focus into their own `FocusScope`.
- Opening a card never changes the layer-shell exclusive zone or moves tiled
  windows.
- Each screen owns its own island state, but global shortcuts open only on the
  focused monitor.

## Visual design

### Compact state

```text
monitor top

                         7 px air gap

              ╭──────────────────────────────────────╮
              │    󰍹  ◫  ◉  │  󱧧        󰂚    │
              ╰──────────────────────────────────────╯

                 one surface, centered as a whole
```

The glyphs above are illustrative. Application and tray items use their actual
icons. The `│` marks an optional subtle separator inside the one surface; it is
not a gap or a second pill.

All dimensions are logical QML pixels:

| Property | Value |
| --- | ---: |
| Top offset | 7 px |
| Compact height | 36 px |
| Outer radius | 12 px |
| Horizontal inner padding | 6 px |
| Vertical inner padding | 4 px |
| Standard icon hit area / all-item slot | 28 × 28 px |
| Standard icon visual size | 15–18 px |
| Tray input and popup-anchor item | 24 × 24 px, centered in its slot |
| Tray application icon | 20 px |
| Gap between item slots | 2 px |
| Group separator | 1 × 18 px |
| Separator side margin | 5 px |
| Border | 1 px `Theme.highlightMed` |
| Background | `Theme.barSurface` |

A 12 px radius keeps the island rectangular rather than making it a full
capsule. The compact width follows its visible content and animates equally on
both sides so its center never drifts away from the monitor center.

An icon's default color is `Theme.text`. Semantic states use the existing Rose
Pine colors:

- active or selected: `Theme.active`;
- available/actionable: `Theme.accent`;
- inactive, disconnected, or unavailable: `Theme.muted`;
- standard hover background: `Theme.hover` at an 8 px radius;
- tray hover/open background: `Theme.hover` on the preserved 24 × 24 px item
  at a 12 px radius, as required by `context-menus.md`;
- urgent/destructive attention: `Theme.love`, used sparingly.

The hover fill is only an interaction highlight. It must not make the icon look
like a separate permanent pill.

### Attached expansion

```text
              ╭──────────────────────────────────────╮
              │   [󰍹] ◫  ◉  │  󱧧        󰂚    │
              │──────────────╯                       ╰╯
              │  Workspace 1                         │
              │  Window previews                     │
              ╰───────────────────────╯
```

The persistent compact island and contextual card use the same background and
share an edge directly. There is no connector, neck, gap, or detached top edge.
The card has square top corners at the join and rounded bottom corners. The
island keeps a rounded lower corner only where no card continues beneath it.
The shared edge must not show an interior border line.

Expanded card geometry:

| Property | Value |
| --- | ---: |
| Distance from island | 0 px; directly shares an edge |
| Card radius | 12 px |
| Card padding | 10 px |
| Minimum width | 180 px |
| Normal maximum width | 420 px |
| Screen-edge margin | 12 px |
| Maximum height | `min(480, screen.height * 0.5)` |
| Border/background | same as compact island |

A mode may request a smaller or larger natural width within those bounds. Long
content scrolls inside the card rather than increasing the card beyond its
maximum height.

### Anchor-relative placement

The trigger chooses the nearest compact-island edge. A trigger in the left half
left-aligns its card; a trigger in the right half right-aligns it:

```text
cardX = triggerCenterX <= compactCenterX
  ? compactLeft
  : compactRight - cardWidth
expandedLeft = min(compactLeft, cardX)
expandedRight = max(compactRight, cardX + cardWidth)
```

Clamp the card to the screen margin when necessary, then widen the island to the
clamped card bounds. A narrow card therefore grows straight down from one edge;
a wider card expands the island toward its overhanging edge or edges.

The anchor is always the actual icon delegate, not a group container or an
index. Dynamic task and tray repeaters can reorder or remove entries, so the
controller keeps an object reference and closes safely if that object is
destroyed.

### Compact overflow

The island's maximum width is `screen.width - 24`. Fixed utility icons remain
visible. When dynamic task or tray items would exceed the available width:

- extra tasks collapse into one stacked-windows icon;
- extra tray items collapse into one overflow icon;
- hovering either overflow icon opens an attached icon grid for that group;
- the overflow card follows the same one-card and anchor rules.

Do not shrink hit areas or icon sizes to force more items into the row.

## Compact item map

Recommended left-to-right order:

```text
Power | Workspaces | Launcher | Running apps | Tray | system status | Updates |
Audio | Bluetooth | Notifications | Clock
```

The separators are visual organization inside one rectangle. A group with no
visible items contributes neither empty space nor a separator.

| Trigger | Compact representation | Hover card | Primary click |
| --- | --- | --- | --- |
| Power | power icon | lock, suspend, log out, reboot, and power off actions | pin/unpin the power card |
| Workspaces | workspace/grid icon with active-state mark | monitor-local workspace row and selected workspace preview | open/pin workspace overview |
| Launcher | search/application-grid icon | application search and bounded result list | pin the focused launcher |
| Running app | application icon | title, workspace, state, and available window actions | focus the window |
| Task overflow | stacked-windows icon | grid/list of hidden running applications | pin/unpin task list |
| Tray item | application-provided icon | application name/status when available | preserve StatusNotifier activation behavior |
| Tray overflow | overflow/tray icon | grid of hidden tray icons | pin/unpin tray grid |
| VRR | monitor/refresh icon | output name and active/inactive VRR state | no action initially |
| Updates | download/update icon; accent dot when updates exist | count, freshness, and bounded package list | open update details in terminal |
| Audio | level-dependent speaker icon | output and microphone sliders, mute state | open `pavucontrol` |
| Bluetooth | Bluetooth icon; accent dot when connected | adapter state and connected devices with battery | pin/unpin device list later |
| Notifications | bell icon; dot when unread | recent notification stack | pin/unpin notification center |
| Clock | clock icon | full time, date, and a small calendar | pin/unpin calendar later |

Workspace numbers, update counts, battery percentages, device names, the date,
and the current time belong in their hover cards. The compact state may change
an icon or show a small non-text badge to make important state glanceable.

Application tasks and tray entries are each independent icon triggers. Their
cards therefore grow from the exact application icon, not from the task/tray
group as a whole. For a tray entry, use the same centered 24 × 24 px item as both
the island-card anchor and the `context-menus.md` popup anchor; the surrounding
28 px slot only participates in row layout.

## Interaction model

### Hover lifecycle

1. Enter an icon hit area.
2. After a 120 ms intent delay, make it the active trigger and load its mode.
3. Grow the card directly from the trigger's nearest island edge.
4. Keep the card open while the pointer is over the trigger or card.
5. When the pointer leaves the whole connected region, start a 180 ms grace
   timer and then close.
6. Re-entering any part of the region cancels the close timer.

The island and card input regions overlap by one pixel, so there is no dead gap
the pointer must cross.

A quick pass over the island should not flash every panel. The intent delay is
skipped when a card is already open: moving to another icon updates the active
mode after 60 ms, moves the shared edge to the new anchor, and morphs the card
to its new dimensions.

### Click and pinning

Hover never traps the pointer or keyboard. Click behavior depends on the item:

- direct-action icons may perform their existing primary action;
- an interactive card can be pinned by clicking its trigger;
- clicking a pinned trigger again closes it;
- clicking another trigger replaces the pinned mode;
- hovering another trigger for 60 ms also replaces the active mode and transfers
  pinned ownership to that trigger; the replacement remains pinned after the
  pointer leaves;
- pointer leave does not close a pinned card;
- Escape, outside click, or a completed action closes a pinned card;
- every pinned mode requests on-demand keyboard focus for Escape/focus-loss
  dismissal; a mode that accepts keyboard input then focuses its own control.

Touch has no hover, so tapping a trigger opens the same card in pinned mode.

The visible treatment for a pinned trigger is the same active icon background
plus a 2 px `Theme.active` mark along the bottom of its hit area. Do not change
the compact island's overall shape merely to indicate pinning.

### Switching between icons

There is one expansion surface and one mode loader. When the pointer moves from
one trigger to another while open, apply the 60 ms switch delay in both
transient and pinned states. A transient card stays transient; a pinned card
transfers `activeMode`, `activeTrigger`, and its context to the hovered trigger
while keeping `pinned: true` and `openReason: "pinned"`. Then:

- retain the card background;
- move the attached card edge horizontally;
- animate card `x`, width, and height to the next mode's target;
- fade and slide the outgoing content by 8 px, swap the single loader source,
  then fade and slide the incoming content into place;
- ignore stale loader completion from the previously requested mode.

The card background stays visible through the sequential content swap and never
resets its geometry. The card must not collapse to zero, detach, or require a
second temporary content loader.

### Animation

Frequent hover interaction should feel quick and controlled, so this design
uses cubic easing without elastic overshoot.

| Transition | Duration | Easing |
| --- | ---: | --- |
| Icon hover fill | 100 ms | `OutCubic` |
| Attached-edge move | 120 ms | `OutCubic` |
| Card open | 180 ms | `OutCubic` |
| Card geometry change | 180 ms | `OutCubic` |
| Content replacement | 120 ms | `OutCubic` |
| Close | 120 ms | `InCubic` |
| Compact width change | 180 ms | `OutCubic` |

Drive island width, card height, and joined-corner radii from the same open
progress. The card's rounded bottom edge moves downward as its content is
revealed, so the surface appears to grow from the island rather than popping in
behind a rectangular clip. Reverse that single motion on close; do not collapse
the card first and round the island in a second transition. Closed/closing input
must remain clipped to the same animated bounds.

Respect a future reduced-motion setting by reducing movement to a short opacity
transition and snapping geometry to its target.

## Architecture

### Window ownership

Use **one `PanelWindow` per screen**. It owns the compact island and attached
card in one transparent top-layer surface:

```text
ShellRoot
├── shared services
└── Variants { model: Quickshell.screens }
    └── Bar / DynamicIsland (one PanelWindow per screen)
        ├── compact background
        │   └── icon trigger row
        └── directly attached expanded card
            └── Loader: one active mode
```

The host may cover a large transparent canvas so it can contain varying card
sizes, but its input `Region` includes only:

- the visible compact island;
- the visible part of the expanded card.

Transparent pixels outside that union must remain click-through. `opacity: 0`
alone is not sufficient.

Keep the exclusive zone stable at the compact footprint:

```text
exclusiveZone = topOffset + compactHeight
```

For the fixed dimensions above this is 43 px. Expanded content overlays the
desktop and never changes this value.

No hover mode, power menu, workspace preview, launcher, audio preview, update
list, notification surface, notification center, or calendar creates another
`PanelWindow`. The current `Launcher.qml` and `NotificationStack.qml` surfaces
must be converted to ordinary mode content and their old panel instances removed
before the one-window acceptance criterion applies.

### Controller state

State is local to each per-screen island:

```qml
property string activeMode: ""
property var activeTrigger: null
property string openReason: "" // hover, pinned, shortcut
property bool pinned: false
property bool triggerHovered: false
property bool cardHovered: false
property real progress: 0
property real targetWidth: 0
property real targetHeight: 0
```

The controller exposes a small request API:

```qml
showHover(mode, trigger, context)
togglePinned(mode, trigger, context)
openPinned(mode, trigger, context)
close(reason)
```

`showHover(...)` updates a transient card normally. If the controller is already
pinned, it replaces the active mode/trigger/context but deliberately preserves
the pinned state; it never silently demotes the replacement to transient.

Mode components expose `implicitWidth` and `implicitHeight`, accept their
feature context, and emit requests such as `closeRequested` or
`openModeRequested`. They do not calculate global window geometry or own hover
close timers.

### Focus and dismissal

- Bind `WlrLayershell.keyboardFocus` to `WlrKeyboardFocus.None` for hover-only
  cards.
- Bind it to `WlrKeyboardFocus.OnDemand` for every pinned card, even when its
  only keyboard command is Escape. A pinned mode with text input or navigation
  additionally focuses its content `FocusScope` after load.
- Escape is handled by the island-level dismissal scope and closes any pinned
  card.
- Outside click or `HyprlandFocusGrab` focus loss closes a pinned card.
- A hover card closes through pointer-region state and does not install a
  full-screen click catcher.
- Global shortcuts are registered once in `ShellRoot` and routed to the island
  on `Hyprland.focusedMonitor`.

### Relationship to tray context menus

`todo/context-menus.md` is a separate implementation-ready milestone. Until it
is deliberately integrated, a tray item's hover information uses the dynamic
island while its right-click action uses the single shell-native anchored
`PopupWindow` specified there. Do not silently merge the two ownership models
while implementing the first island slice.

The two surfaces are mutually exclusive. On any tray-menu toggle request, close
the island card before opening the popup and latch hover suppression for that
tray trigger. Keep suppression active while the popup is visible and after it
closes until the pointer exits the trigger; a fresh pointer entry starts the
normal 120 ms hover-intent delay. This prevents a focused tray popup and an
island card from overlapping or immediately reopening one another.

A later design may render tray action menus in a pinned island card, but that
requires updating both specifications together.

## Initial mode content

### Power — first vertical slice

Power is the first mode because it proves connected hover, pinning, action
input, dismissal, and geometry without requiring asynchronous models.

- Hover shows icon-led actions for Lock, Suspend, Log Out, Reboot, and Power
  Off.
- Labels are allowed in the expanded card; compact mode remains icon-only.
- Click pins the card.
- Destructive actions require confirmation or a deliberate second step.
- Commands live in a shared service, not in visual delegates.
- Close the card before handing off to lock, logout, reboot, or shutdown.

### Audio — first information-rich hover card

- Show default output and microphone rows.
- Each row has an icon, name, level, slider, and mute action.
- Hover does not grab focus.
- Slider and mute interaction keep the card open because the pointer remains
  inside its region.
- Clicking the compact audio trigger opens `pavucontrol` and closes the hover
  card unless the trigger is being used to pin a future device selector.

### Workspace preview

- The compact island has one workspace/grid icon rather than numeric segments.
- The card shows monitor-local workspaces and their numbers inside the expanded
  content.
- Preview only the selected/hovered workspace initially.
- Still captures are the default; live captures run only while needed.
- Clicking a workspace activates it; clicking a window focuses it.

### Updates

- The compact update icon shows only an accent dot when updates are available.
- The card shows count, last refresh time, loading/error state, and a bounded
  package list.
- Shared update data must treat `dnf check-update` exit code 100 as success with
  available updates.
- Hovering must not start a new process every time; refresh only when cached data
  is stale.

### Launcher

- Keep the existing process-global `GlobalShortcut`, app model, search scoring,
  result navigation, and launch behavior.
- Replace `Launcher.qml`'s per-screen `Variants`/`PanelWindow` views with one
  ordinary launcher mode loaded by the target island.
- The shortcut routes an `openPinned("launcher", ...)` request to the island on
  `Hyprland.focusedMonitor` and anchors it to the compact launcher icon.
- Focus the search field after load. Escape, focus loss, and launching an app
  close the island and reset the query after the close transition.
- Remove the old launcher panels only after shortcut routing and focus behavior
  work through the island.

### Clock and notifications

- The clock card owns all date/time text and the calendar.
- Preserve `NotificationService` as the shared source of truth for records,
  focused-screen routing, queued records, timeout pausing, fullscreen
  suppression, and manual fullscreen override.
- Replace `NotificationStack.qml`'s `PanelWindow` with ordinary notification
  mode content loaded in the service's `routedScreen` island and anchored to
  that screen's bell icon.
- A new notification automatically opens a transient notification card only
  when fullscreen suppression allows it and that island has no pinned user
  mode. If a pinned mode owns the island, keep the record queued for visual
  presentation and show the compact bell's unread dot rather than displacing
  the user's mode.
- Pointer hover over the notification card continues to pause record timers.
  When suppression clears or the pinned mode closes, reveal queued records on
  the service-selected island. Clicking the bell pins the full notification
  center for actions.
- Remove the old notification panel only after automatic presentation, routing,
  queuing, timeout behavior, and fullscreen suppression have been verified in
  the island host.

## Implementation sequence

1. Replace the three-zone `Bar.qml` layout with one centered compact background
   while preserving current actions behind icon triggers.
2. Expand the per-screen host, add the exact compact input mask, and verify that
   transparent areas remain click-through.
3. Add the attached card shell, island-widening geometry, one-mode controller,
   hover intent timer, close grace timer, and clamping with placeholder content.
4. Implement the power vertical slice and verify hover-to-card pointer travel,
   pinning, Escape, outside click, and destructive-action safety.
5. Convert status text to icon states and attached cards: clock, VRR, updates,
   audio, and Bluetooth.
6. Convert the launcher into ordinary mode content, route its existing global
   shortcut to the focused island, then remove its per-screen panel surfaces.
7. Convert the notification stack into ordinary mode content while preserving
   service routing, queuing, timers, fullscreen suppression, and automatic
   presentation; then remove its independent panel surface.
8. Consolidate workspaces into one icon and move workspace information/preview
   into its card.
9. Connect running-app and tray delegates as independent anchors; add dynamic
   overflow and tray-popup hover suppression.
10. Reconcile tray action menus with `context-menus.md` only as an explicit later
    design change.

## Acceptance criteria

### Visual

- Each monitor shows one rounded rectangle centered 7 px below its top edge.
- The compact island contains icons only; no date, time, workspace number,
  package count, device name, battery percentage, or other text is visible.
- Permanent controls do not look like separate pills.
- Hovering any information-bearing icon opens one card below it.
- The card grows directly from the island edge nearest its trigger with no stub.
- A card wider than the compact island widens the island to meet its outer edge.
- Near screen edges, the card remains on-screen and the island meets its bounds.
- The card and compact island use one coherent background, border, radius, and
  Rose Pine visual language.

### Interaction

- Passing quickly over icons does not flash multiple cards.
- Moving directly from a trigger into the attached card never closes it.
- Moving across icons reuses one expansion surface and smoothly changes its
  anchor and content; when the old card is pinned, the new hovered card inherits
  that pinned ownership and remains open after pointer leave.
- Leaving the connected region closes a transient card after the grace delay.
- Interactive controls in a hover card remain usable without pinning.
- Pinned modes survive pointer leave and close on Escape, outside click, toggle,
  or completed action.
- Opening a tray context menu closes and suppresses the tray hover card so the
  two surfaces never overlap.
- A destroyed/reordered task or tray trigger cannot leave an orphaned card.

### Architecture and robustness

- There is one `PanelWindow` per screen—the island host—and at most one loaded
  island mode per screen; the former launcher and notification panels are gone.
- The launcher shortcut opens the pinned launcher on the focused island with
  search focus and the existing result behavior.
- Notification routing, queuing, timer pausing, fullscreen suppression, and
  automatic presentation still work through the routed island.
- The exclusive zone remains 43 px whether the card is open or closed.
- Transparent surface areas do not intercept desktop input.
- Closed/closing content cannot receive clicks even while an opacity animation
  is running.
- Hover-only cards do not take keyboard focus.
- Global modes open only on the focused monitor; pointer hover opens only on the
  monitor containing that trigger.
- Dynamic content reports implicit dimensions and scrolls within fixed maximum
  bounds.
- Quickshell reloads without QML errors and without launching a second `qs`
  process.

## Repository and API references

- Current per-screen bar: `config/quickshell/home/Bar.qml`
- Current dimensions: `config/quickshell/home/config/BarMetrics.qml`
- Current status content: `config/quickshell/home/widgets/StatusArea.qml`
- Current workspace behavior: `config/quickshell/home/widgets/WorkspaceSwitcher.qml`
- Current power behavior: `config/quickshell/home/widgets/PowerMenu.qml`
- Tray-menu milestone: `config/quickshell/todo/context-menus.md`
- Hyprland and workspace-preview notes: `config/quickshell/hyprland.md`
- Quickshell 0.3.1 [`PanelWindow`](https://quickshell.org/docs/v0.3.1/types/Quickshell/PanelWindow/)
- Quickshell 0.3.1 [`HyprlandFocusGrab`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandFocusGrab/)
- Quickshell 0.3.1 [`GlobalShortcut`](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/GlobalShortcut/)
- Quickshell 0.3.1 [`Region`](https://quickshell.org/docs/v0.3.1/types/Quickshell/Region/)
