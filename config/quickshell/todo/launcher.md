# Quickshell application launcher

Research and implementation notes for replacing the current `rofi -show drun`
launcher. The target is deliberately small: discover desktop applications,
filter them with a fuzzy search, show each application's icon and name, and
launch the selected entry. The launcher should appear at the bottom center and
grow upward.

The installed Quickshell is 0.3.1. Quickshell already provides the desktop-entry
and layer-shell pieces; the only genuinely custom part needed here is a small
fuzzy matcher.

## Recommended shape

```text
GlobalShortcut / Hyprland keybind
                |
                v
          open/closed state
                |
                v
  per-screen PanelWindow (transparent, top layer, bottom anchored content)
                |
                +--> ScriptModel(DesktopEntries.applications.values)
                |          |
                |          +--> ListView delegate: IconImage + Text
                |
                +--> TextField -> fuzzy match -> current result
```

Use these standard APIs:

- `DesktopEntries.applications.values` for the XDG application database.
- `DesktopEntry.name`, `DesktopEntry.icon`, and `DesktopEntry.execute()` for
  the row and launch operation.
- `ScriptModel` to turn a filtered JavaScript array into a `ListView` model.
- `TextField`, `ListView`, `IconImage`, `Text`, `Rectangle`, and `MouseArea`
  for the UI.
- `Quickshell.iconPath(entry.icon, "image-missing")` for themed icons.
- `PanelWindow` with `WlrLayershell` for a non-reserving overlay.
- `GlobalShortcut` for a native Hyprland global shortcut, and optionally
  `HyprlandFocusGrab` for dismissal when clicking outside the launcher.
- A normal `NumberAnimation` for the reveal animation.

No desktop-file parser, subprocess, SQLite plugin, or external fuzzy-search
library is required. The current `config/rofi/drun.rasi` explicitly parses user
and system entries and searches `name,generic,exec,categories,keywords`;
`DesktopEntries` replaces the first part, while the minimal matcher can start
with `name`/`genericName` and add the other fields only if exact rofi matching
is important.

## What `~/code/shell` does

The reference launcher is part of a much larger Caelestia shell. Its relevant
files are:

| File | Responsibility |
| --- | --- |
| `modules/launcher/services/Apps.qml` | Gets application entries, searches them, and launches them. |
| `utils/Searcher.qml` | Generic search service. It uses vendored `fzf.js` or `fuzzysort.js`. |
| `modules/launcher/AppList.qml` | Converts search text into a `ScriptModel`, owns the `ListView`, current item, and keyboard navigation. |
| `modules/launcher/items/AppItem.qml` | Renders the icon, name, secondary text, favourite marker, and click handler. |
| `modules/launcher/Content.qml` | Places the result list above the search field and handles Enter/Escape. |
| `modules/launcher/ContentList.qml` | Gives the list a bounded, animated implicit height. |
| `modules/launcher/Wrapper.qml` | Places the whole launcher at the bottom and implements the slide/grow animation. |
| `modules/drawers/Panels.qml` | Centers the wrapper horizontally and anchors it to the bottom of the screen. |
| `modules/drawers/ContentWindow.qml` | Provides the full-screen layer-shell window, keyboard focus, and focus grab. |
| `modules/Shortcuts.qml` | Toggles `screenState.launcher` from a Hyprland global shortcut. |

### Desktop entries and launching

`Apps.qml` does not parse `.desktop` files itself. It uses Quickshell's
`DesktopEntries.applications.values`, which is the important part to reuse.
The reference then filters hidden IDs through its own configuration and wraps
the entries in `AppDb`.

`AppDb` is extra Caelestia machinery, not a Quickshell requirement. It provides:

- a persistent SQLite frequency count;
- favourite-first and frequently-used sorting;
- wrappers exposing searchable fields; and
- delayed model updates when the desktop-entry list changes.

For this launcher, a plain array sorted by `name` is sufficient. On activation,
the reference ultimately calls `entry.execute()`. It has an additional branch
for entries marked `runInTerminal`, where it constructs a terminal command and
runs a wrapper script. That branch can be added later if terminal desktop files
need special treatment; ordinary entries should use `DesktopEntry.execute()` so
that desktop-entry command-field semantics are preserved.

### Search

`Searcher.qml` normalizes whitespace and offers two modes:

- normal mode uses the vendored `fzf.js` finder; and
- fuzzy mode uses the vendored `fuzzysort.js` implementation, with configurable
  weighted fields.

`Apps.qml` searches only the `name` field for an ordinary query. The additional
`@i`, `@c`, `@d`, `@e`, `@w`, `@g`, and `@k` prefixes search ID, categories,
comment, command, startup class, generic name, or keywords. Those prefixes are
not needed for the rofi replacement.

Quickshell 0.3.1 does not provide a ready-made fuzzy text filter. A short
case-insensitive subsequence scorer in QML/JavaScript is enough for this use
case. It can rank contiguous matches and word-boundary matches above loose
subsequence matches without bringing over either of the reference libraries.

### Rows and search field

`AppItem.qml` is the relevant visual core:

```qml
IconImage {
    asynchronous: true
    source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
    implicitSize: parent.height * 0.8
}

StyledText {
    text: root.modelData?.name ?? ""
}
```

The reference also displays `comment` or `genericName`, a favourite icon, a
custom hover/ripple layer, and custom fonts/colors. Only the icon and name are
needed here. A stock `Rectangle` plus `MouseArea` is enough for selection.

### Bottom-up animation

`modules/launcher/Wrapper.qml` is the key file. The launcher is an `Item`
inside a full-screen layer-shell window, not a separate desktop window. It is
centered and bottom-anchored by `Panels.qml`. Its animation is:

```qml
property real offsetScale: shouldBeActive ? 0 : 1

visible: offsetScale < 1
anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
opacity: 1 - offsetScale

Behavior on offsetScale {
    Anim {}
}
```

`offsetScale == 0` is open: the bottom margin is zero and the content is fully
opaque. `offsetScale == 1` is closed: the item is translated below the screen
by its own height plus five pixels and becomes invisible. Because the item is
anchored to the bottom, the content appears to grow upward from the bottom
edge. This is the part worth copying almost verbatim; `Anim` can be replaced
by an ordinary `NumberAnimation`.

The content's height is based on its implicit height:

- the search field is at the bottom;
- the result list is above it;
- the list height is limited to a maximum number of rows; and
- `Behavior` animations on the list/content implicit dimensions make the panel
  resize smoothly as the query changes.

The reference deliberately breaks the `implicitHeight` binding when closing so
that a changing result list cannot change the panel height during the close
animation. Start without that complication. Add the same binding break only if
closing while typing produces a visible jump.

### Window, focus, and dismissal

`ContentWindow.qml` creates a full-screen `PanelWindow` for each screen with:

```qml
WlrLayershell.exclusionMode: ExclusionMode.Ignore
WlrLayershell.layer: WlrLayer.Top
WlrLayershell.keyboardFocus: launcherOpen
    ? WlrKeyboardFocus.OnDemand
    : WlrKeyboardFocus.None
```

The window does not reserve space from tiled applications. The launcher item
itself is the only visible part. `HyprlandFocusGrab` closes the drawer when the
compositor reports a click outside the listed window. A full-screen transparent
`MouseArea` behind the card is an equally reasonable simple first pass.

`Content.qml` calls `forceActiveFocus()` on the search field when the launcher
is created/opened. Enter launches the current row, the arrow keys change the
current index, and Escape clears the launcher state. A click on a row launches
it immediately.

## Minimal recreation for this dotfiles shell

Keep the first version as one `Launcher.qml` next to
`quickshell/home/shell.qml`. Add `Launcher {}` to the existing `ShellRoot`, and
let it own one `open` boolean and one `GlobalShortcut`. Use a `Variants` model
of `Quickshell.screens` so the small panel can be created on the same monitor as
the bar. To avoid showing it on every monitor, make the panel visible only when
its `screen` matches `Hyprland.focusedMonitor` (compare monitor names through
`Hyprland.monitorFor(screen)`). If multi-monitor behavior is not important at
first, a single chosen screen is simpler.

The following is an intentionally small skeleton. It shows the data flow and
animation; styling, colors, and exact dimensions should follow the existing
`Bar.qml` rather than the Caelestia theme. The file needs `QtQuick`,
`QtQuick.Controls`, `Quickshell`, `Quickshell.Hyprland`, `Quickshell.Wayland`,
and `Quickshell.Widgets`.

### Model and fuzzy search

```qml
property var apps: []

function reloadApps() {
    apps = [...DesktopEntries.applications.values]
        .filter(app => !app.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name));
}

function subsequenceScore(needle, haystack) {
    let cursor = 0;
    let score = 0;

    for (let i = 0; i < needle.length; i++) {
        const position = haystack.indexOf(needle[i], cursor);
        if (position < 0)
            return -Infinity;

        score += position === cursor ? 2 : 1;
        if (position === 0 || /[\s._-]/.test(haystack[position - 1]))
            score += 4;
        cursor = position + 1;
    }

    // Prefer shorter names when the match quality is otherwise equal.
    return score - haystack.length * 0.01;
}

function resultsFor(query) {
    const needle = query.trim().toLowerCase();
    if (!needle)
        return apps;

    return apps.map(app => {
        const name = String(app.name || "").toLowerCase();
        const genericName = String(app.genericName || "").toLowerCase();
        return {
            entry: app,
            score: Math.max(
                subsequenceScore(needle, name),
                subsequenceScore(needle, genericName)
            )
        };
    }).filter(result => result.score > -Infinity)
      .sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name))
      .map(result => result.entry);
}

Component.onCompleted: reloadApps()

Connections {
    target: DesktopEntries
    function onApplicationsChanged() {
        root.reloadApps();
    }
}
```

Then bind the list to a stock `ScriptModel`:

```qml
ScriptModel {
    id: resultModel
    values: root.resultsFor(searchField.text)
}

ListView {
    id: list
    model: resultModel
    clip: true
    currentIndex: count > 0 ? 0 : -1
    implicitHeight: Math.min(contentHeight, 8 * 52)
    height: implicitHeight
}
```

If matching only the visible application name is preferred, remove the
`genericName` score. If rofi-style searching across comment, executable, or
keywords is eventually needed, add those fields to the score object rather
than importing the entire Caelestia search service.

### Panel and animation

The essential structure is:

```qml
PanelWindow {
    id: panel
    screen: modelData
    readonly property bool activeScreen: Hyprland.monitorFor(screen)?.name === Hyprland.focusedMonitor?.name
    visible: activeScreen && (root.open || animatedPanel.visible)
    color: "transparent"

    // Keep the panel out of the exclusive layout zone.
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.open && activeScreen
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Item {
        id: animatedPanel

        width: 560
        height: implicitHeight
        implicitHeight: card.implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        property real offsetScale: root.open ? 0 : 1

        visible: panel.activeScreen && offsetScale < 1
        anchors.bottomMargin: (-implicitHeight - 8) * offsetScale
        opacity: 1 - offsetScale

        Behavior on offsetScale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 16
            color: "#f2e9e1"
            implicitHeight: body.implicitHeight + 24

            Column {
                id: body
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                ListView {
                    id: list
                    // model and delegate omitted here
                    width: parent.width
                    height: Math.min(contentHeight, 8 * 52)
                    clip: true
                }

                TextField {
                    id: searchField
                    width: parent.width
                    placeholderText: "Search applications"

                    onAccepted: {
                        if (list.currentItem)
                            root.launch(list.currentItem.modelData);
                    }
                    Keys.onEscapePressed: root.open = false
                    Keys.onUpPressed: {
                        list.currentIndex = Math.max(0, list.currentIndex - 1);
                        event.accepted = true;
                    }
                    Keys.onDownPressed: {
                        list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1);
                        event.accepted = true;
                    }
                    onVisibleChanged: {
                        if (visible && root.open)
                            forceActiveFocus();
                    }
                }
            }
        }
    }
}
```

The real delegate only needs the following fields:

```qml
Item {
    required property DesktopEntry modelData
    width: ListView.view.width
    height: 52

    IconImage {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 36
        source: Quickshell.iconPath(modelData.icon, "image-missing")
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 48
        anchors.verticalCenter: parent.verticalCenter
        text: modelData.name
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.launch(modelData)
    }
}
```

The outer `PanelWindow` must remain alive until the slide-out finishes. Either
keep it always present with a transparent input mask, as the reference does,
or bind its `visible` property to `root.open || animatedPanel.visible`. Do not
bind the window directly to `root.open`, or the window will disappear before
its close animation can play.

The launcher action is intentionally just:

```qml
function launch(entry) {
    if (!entry)
        return;
    entry.execute();
    root.open = false;
}
```

For a full implementation, add a transparent `MouseArea` behind `card` that
sets `root.open = false`, or add:

```qml
HyprlandFocusGrab {
    active: root.open
    windows: [panel]
    onCleared: root.open = false
}
```

### Shortcut wiring

Register the shortcut once, outside the per-screen `Variants`:

```qml
GlobalShortcut {
    appid: "quickshell"
    name: "launcher"
    description: "Toggle application launcher"
    onPressed: root.open = !root.open
}
```

Bind it in Hyprland with the existing Lua helper:

```lua
hl.bind(main_mod .. " + R", hl.dsp.global("quickshell:launcher"))
```

This replaces the current `hl.dsp.exec_cmd(apps)` binding in
`config/mise/templates/hypr/hyprland.lua`; the separate `rofi -show window`
binding can remain. The equivalent native Hyprland syntax is:

```ini
bind = SUPER, R, global, quickshell:launcher
```

When opening, set keyboard focus to the `TextField`. When closing, clear the
query and let `WlrKeyboardFocus` return to `None`. Escape, Enter, row clicks,
and an outside click should all close the launcher after their action.

## What not to port from the reference

Avoid these until the basic launcher is useful:

- `Caelestia.Config`, `Tokens`, `Colours`, and all `Styled*` components;
- `AppDb`, SQLite frequency tracking, favourites, and hidden-app regexes;
- `fzf.js`, `fuzzysort.js`, and weighted multi-field search;
- action, calculator, wallpaper, scheme, and variant modes;
- the terminal wrapper for `runInTerminal` entries;
- `StateLayer`, deformation matrices, blob backgrounds, and custom transitions;
- the reference's full drawer/region system for bars, dashboards, sidebars, and
  session controls.

Those features explain most of the reference implementation's size. They are
not needed to reproduce its useful behavior: a centered card whose bottom edge
stays at the screen edge while its list, icon rows, and search field slide in.

## Integration checklist

1. Add a small `Launcher.qml` to `quickshell/home/` and instantiate it from
   `home/shell.qml`.
2. Use `DesktopEntries.applications.values`; do not recreate XDG desktop-file
   discovery in a shell script.
3. Start with name/generic-name subsequence matching and alphabetical ordering.
4. Use `PanelWindow`/`WlrLayershell` with `ExclusionMode.Ignore`, a bottom-
   centered child, and the `anchors.bottomMargin` animation above.
5. Give the search field focus on open and handle Escape, arrows, Enter, and
   mouse activation.
6. Replace only the drun keybind in `hyprland.lua`; leave the window switcher
   alone.
7. Verify that a closed launcher does not intercept bar/application clicks and
   that a changing result count resizes upward from the bottom rather than
   moving the bottom edge.

The existing `quickshell/hyprland.md` contains the local Quickshell 0.3.1 notes
for `PanelWindow`, `GlobalShortcut`, `WlrKeyboardFocus`, and
`HyprlandFocusGrab`. The reference source remains useful for visual comparison,
but the minimal version should stay independent of its Caelestia-specific
components.
