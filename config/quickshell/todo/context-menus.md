# Quickshell context and tray menus

## Recommendation

Quickshell gives us the tray item and menu data, but it does not require us to
use one particular visual treatment. There are three useful levels of control:

| Approach | API | Trade-off |
| --- | --- | --- |
| Platform menu | `SystemTrayItem.display(window, x, y)` | Very little code; Quickshell owns the menu surface and styling. |
| Anchored menu | `QsMenuAnchor` | Quickshell positions a `QsMenuHandle`; still less control than drawing the menu ourselves. |
| Custom renderer | `QsMenuOpener` + `QsMenuEntry` | Full theme control; we own layout, popup lifetime, focus, and submenu behavior. |

The current bar uses the first approach. A future themed implementation should
probably use the third approach, but only for the small subset of menu behavior
we actually need.

Quickshell is pre-1.0. The local installation is 0.3.1, so check the installed
API and generated QML type metadata when implementation starts.

## Menu data flow

The SystemTray module is a StatusNotifier host. The application supplies the
menu structure; Quickshell exposes it as QML objects:

```text
SystemTray.items
  -> SystemTrayItem
       -> menu: QsMenuHandle
            -> QsMenuOpener.children
                 -> QsMenuEntry
```

A `SystemTrayItem` provides:

- `icon`, `title`, `id`, `status`, and `hasMenu`;
- `activate()` and `secondaryActivate()` for normal tray actions;
- `menu`, a `QsMenuHandle`;
- `display(parentWindow, relativeX, relativeY)`, which asks Quickshell to
  display the item's menu.

A `QsMenuEntry` provides the semantic information a custom renderer needs:

- `text`, `icon`, and `enabled`;
- `isSeparator`;
- `hasChildren` for nested menus;
- `buttonType` and `checkState` for checkbox/radio entries;
- the `triggered()` signal for activating a leaf entry.

The application remains responsible for the menu's actions and live updates.
The shell should call `entry.triggered()` rather than attempting to reproduce
its D-Bus behavior.

## Existing local example: platform-owned menu

`config/quickshell/home/Bar.qml` already has the minimal implementation. Its
tray repeater uses `SystemTray.items` and, on a right click, does this:

```qml
if (event.button === Qt.RightButton && modelData.hasMenu) {
  modelData.display(
    panel,
    tray.x + trayItem.x,
    trayItem.y + trayItem.height
  )
} else {
  modelData.activate()
}
```

The coordinates are relative to the `PanelWindow`; placing the menu below the
tray item is handled by `display()`. This is the right default when native or
platform-provided menu appearance is acceptable. It avoids implementing:

- a second popup window;
- menu sizing and placement;
- outside-click and Escape dismissal;
- submenu navigation;
- menu lifetime while the tray item updates.

It is not the right foundation if the menu must look exactly like the rest of
our Rose Pine bar. In that case, the menu surface and rows need to be QML that
we control.

`QsMenuAnchor` is the middle option when we want Quickshell-managed positioning
without calling `SystemTrayItem.display()` directly. It is not needed for the
fully custom renderer.

## Reference implementation: Caelestia shell

`~/code/shell` demonstrates the custom approach used by the Caelestia shell.
The relevant path is:

```text
modules/bar/components/Tray.qml
  -> modules/bar/Bar.qml
  -> modules/bar/popouts/Content.qml
  -> modules/bar/popouts/TrayMenu.qml
```

### Selecting a menu

`modules/bar/components/Tray.qml` and `modules/bar/popouts/Content.qml` both
build their models from the same filtered `SystemTray.items` list. This keeps a
visible tray icon's index aligned with its `traymenuN` popout.

When the pointer is over the bar, `modules/bar/Bar.qml`:

1. identifies the tray item under the pointer;
2. sets `popouts.currentName` to `traymenu${index}`;
3. records the tray item's vertical center;
4. expands the compact tray when necessary.

`Content.qml` has one lazy popout per item and passes the menu handle into the
custom component:

```qml
TrayMenu {
    popouts: root.popouts
    trayItem: trayMenu.modelData.menu
}
```

The surrounding popout wrapper positions and clips the menu beside the bar.
The reference also uses focus-grab behavior to keep a nested menu open while
the pointer moves from the bar into the popout.

### Rendering rows

`modules/bar/popouts/TrayMenu.qml` is a `StackView`. Each stack item is a
`Column` containing a `QsMenuOpener` and a `Repeater` over
`menuOpener.children`:

```qml
QsMenuOpener {
    id: menuOpener
    menu: menu.handle
}

Repeater {
    model: menuOpener.children

    delegate: /* custom QML row */
}
```

Each row is a fixed-width `StyledRect`. The reference renderer:

- renders separators as one-pixel `m3outlineVariant` lines;
- uses `IconImage` for the entry icon;
- uses `StyledText` for the label and elides long labels;
- disables the row and changes its text/icon to `m3outline` when needed;
- adds a `StateLayer` for hover, press, and ripple feedback;
- adds a Material `chevron_right` when `hasChildren` is true;
- calls `modelData.triggered()` for leaf entries;
- pushes another `QsMenuHandle` onto the `StackView` for submenus;
- adds a themed `Back` row to nested menus.

The renderer is deliberately separate from the tray icon renderer. The tray
icon uses `SystemTrayItem.icon` and can optionally be recolored; menu entries
use the icon path supplied by each menu entry.

### Where the theme comes from

The menu rows use the same primitives as the rest of the shell:

- `StyledText.qml` supplies the body font and `m3onSurface` text color;
- `MaterialIcon.qml` supplies the icon font;
- `StateLayer.qml` supplies themed hover/ripple behavior and animation;
- `Tokens` supplies width, padding, spacing, rounding, and animation curves;
- `Colours.qml` supplies the current Material-style palette.

The menu itself does not draw its own opaque background. The parent drawer's
`popoutBg` in `modules/drawers/ContentWindow.qml` is a `BlobRect` in the shared
surface-colored `BlobGroup`. That shared background, shadow, rounded shape, and
movement deformation are a large part of why the menu looks native to the
Caelestia shell rather than like an unrelated application menu.

### What the reference does not render

Although `QsMenuEntry` exposes `buttonType` and `checkState`, the Caelestia
renderer only visibly handles separators, enabled state, text, icons, and
submenus. It does not draw checkbox or radio indicators. That is a useful
pruning point for our implementation: add checkable state only after a real
tray application requires it.

## Proposed smaller implementation

When we revisit this, keep the data path and discard most of the Caelestia
infrastructure:

1. Keep the existing `SystemTray.items` repeater and tray icon behavior.
2. Open a custom menu on right click rather than reproducing Caelestia's
   hover-to-open and compact-tray logic.
3. Put a single `TrayMenu` component in an anchored popup/window.
4. Feed it `modelData.menu` through `QsMenuOpener`.
5. Initially support only separators, icons, text, disabled entries, leaf
   activation, and one level of submenus.
6. Reuse the bar's existing Rose Pine colors, font, padding, and hover
   rectangle instead of introducing Caelestia's C++ configuration/plugin.
7. Close on outside click and Escape; let `QsMenuEntry.triggered()` perform
   the application action.

A minimal row model looks like this:

```qml
QsMenuOpener {
    id: opener
    menu: root.menu
}

Column {
    Repeater {
        model: opener.children

        delegate: Rectangle {
            required property QsMenuEntry modelData

            width: 260
            height: modelData.isSeparator ? 1 : 30
            color: modelData.isSeparator
                ? root.mutedColor
                : rowMouse.containsMouse ? root.hoverColor : "transparent"

            Text {
                visible: !modelData.isSeparator
                anchors.centerIn: parent
                text: modelData.text
                color: modelData.enabled ? root.textColor : root.mutedColor
                elide: Text.ElideRight
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !modelData.isSeparator && modelData.enabled

                onClicked: modelData.triggered()
            }
        }
    }
}
```

That snippet omits submenu navigation and icon layout on purpose. Add those as
small, tested extensions rather than copying the full reference component.

### Features to defer

Do not initially copy:

- per-monitor token/configuration plumbing;
- asynchronous loaders for every small row;
- blob deformation and custom ripple shaders;
- hover-triggered tray expansion and popout indexing;
- notification/sidebar focus coordination;
- checkbox/radio indicators unless needed;
- a full context-menu abstraction for unrelated shell controls.

The first useful milestone is a right-click menu that is visually consistent,
correctly activates real tray entries, handles separators and disabled entries,
and closes reliably. The Caelestia implementation is a presentation reference,
not a component that should be transplanted wholesale.

## References

### Local files

- Current platform-owned tray menu: `config/quickshell/home/Bar.qml`
- Current Quickshell entry point: `config/quickshell/home/shell.qml`
- Quickshell version notes: `config/quickshell/hyprland.md`
- Caelestia tray renderer: `~/code/shell/modules/bar/popouts/TrayMenu.qml`
- Caelestia tray popout creation: `~/code/shell/modules/bar/popouts/Content.qml`
- Caelestia popout background: `~/code/shell/modules/drawers/ContentWindow.qml`

### Quickshell documentation

- [SystemTrayItem](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.SystemTray/SystemTrayItem/)
- [SystemTray](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.SystemTray/SystemTray/)
- [QsMenuAnchor](https://quickshell.org/docs/v0.3.1/types/Quickshell/QsMenuAnchor/)
- [QsMenuOpener](https://quickshell.org/docs/v0.3.1/types/Quickshell/QsMenuOpener/)
- [QsMenuEntry](https://quickshell.org/docs/v0.3.1/types/Quickshell/QsMenuEntry/)
- [System Tray specification](https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/)
