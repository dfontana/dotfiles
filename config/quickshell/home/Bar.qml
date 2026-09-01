import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.config
import qs.theme
import qs.widgets

PanelWindow {
  id: root

  property var modelData
  required property var launcherService
  required property var notificationService

  screen: modelData
  color: "transparent"
  exclusiveZone: BarMetrics.compactFootprint
  implicitHeight: Math.max(BarMetrics.compactFootprint,
    launcherDrawer.y + launcherDrawer.implicitHeight)
  mask: islandInputRegion
  focusable: root.launcherTarget
  surfaceFormat: {
    "opaque": false
  }

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: root.launcherTarget
    ? WlrKeyboardFocus.OnDemand
    : WlrKeyboardFocus.None

  HyprlandFocusGrab {
    active: root.launcherTarget
    windows: [root]
    onCleared: root.launcherService.closeLauncher()
  }

  anchors {
    top: true
    left: true
    right: true
  }

  readonly property var monitor: Hyprland.monitorFor(screen)
  readonly property bool primary: screen && screen.name === BarMetrics.primaryOutput
  readonly property bool focusedScreen: {
    const monitor = root.screen ? Hyprland.monitorFor(root.screen) : null;
    return monitor && monitor.name === Hyprland.focusedMonitor?.name;
  }
  readonly property bool launcherTarget: Boolean(root.launcherService
    && root.launcherService.launcherOpen
    && root.focusedScreen
    && root.screen
    && root.launcherService.targetOutput === root.screen.name)

  Region {
    id: islandInputRegion

    Region {
      item: island
      shape: RegionShape.Rect
      radius: BarMetrics.compactRadius
    }

    Region {
      x: launcherDrawer.x + launcherDrawer.connectorX
      y: launcherDrawer.y
      width: launcherDrawer.connectorWidth
      height: Math.min(launcherDrawer.connectorHeight,
        launcherDrawer.inputHeight)
    }

    Region {
      x: launcherDrawer.x
      y: launcherDrawer.y + launcherDrawer.cardTop
      width: launcherDrawer.width
      height: launcherDrawer.fullHeight - launcherDrawer.cardTop
      radius: launcherDrawer.cardRadius

      Region {
        x: launcherDrawer.x
        y: launcherDrawer.y + launcherDrawer.cardTop
        width: launcherDrawer.width
        height: Math.max(0, launcherDrawer.inputHeight - launcherDrawer.cardTop)
        intersection: Intersection.Intersect
      }
    }
  }

  Rectangle {
    id: island

    x: Math.round((root.width - width) / 2)
    y: BarMetrics.compactTopOffset
    width: compactRow.implicitWidth + BarMetrics.compactHorizontalPadding * 2
    height: BarMetrics.compactHeight
    radius: BarMetrics.compactRadius
    color: Theme.barSurface
    border.width: 1
    border.color: Theme.highlightMed

    Behavior on width {
      NumberAnimation {
        duration: 180
        easing.type: Easing.OutCubic
      }
    }

    Row {
      id: compactRow

      anchors.centerIn: parent
      spacing: BarMetrics.compactItemGap

      PowerMenu {}

      WorkspaceSwitcher {
        monitor: root.monitor
        screen: root.screen
      }

      CompactIconButton {
        id: launcherButton

        icon: ""
        iconSize: 16
        iconColor: Theme.text
        onClicked: root.launcherService.toggleLauncher(
          root.screen ? root.screen.name : "")
      }

      IslandSeparator {
        visible: taskList.visible || systemTray.visible
      }

      TaskList {
        id: taskList
        monitor: root.monitor
      }

      SystemTray {
        id: systemTray
        hostWindow: root
      }

      IslandSeparator {
        visible: taskList.visible || systemTray.visible
      }

      StatusArea {
        outputName: root.screen ? root.screen.name : ""
        updatesEnabled: root.primary
        notificationService: root.notificationService
        screen: root.screen
      }
    }
  }

  LauncherDrawer {
    id: launcherDrawer

    service: root.launcherService
    screen: root.screen
    screenActive: root.focusedScreen
    anchorCenterX: island.x + launcherButton.mapToItem(island,
      launcherButton.width / 2, 0).x
    y: island.y + island.height
  }
}
