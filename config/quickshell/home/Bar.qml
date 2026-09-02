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
    launcherDrawer.y + launcherDrawer.implicitHeight,
    workspaceDrawer.y + workspaceDrawer.implicitHeight)
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
  readonly property real compactTargetWidth: compactRow.implicitWidth
    + BarMetrics.compactHorizontalPadding * 2
  property real compactWidth: root.compactTargetWidth
  readonly property real compactLeft: (root.width - root.compactWidth) / 2
  readonly property real compactRight: root.compactLeft + root.compactWidth
  readonly property real workspaceProgress: workspaceDrawer.visible
    ? workspaceDrawer.openProgress : 0
  readonly property real launcherProgress: launcherDrawer.visible
    ? launcherDrawer.openProgress : 0
  readonly property real workspaceAnimatedLeft: root.compactLeft
    + (Math.min(root.compactLeft, workspaceDrawer.x) - root.compactLeft)
      * root.workspaceProgress
  readonly property real workspaceAnimatedRight: root.compactRight
    + (Math.max(root.compactRight,
      workspaceDrawer.x + workspaceDrawer.width) - root.compactRight)
      * root.workspaceProgress
  readonly property real launcherAnimatedLeft: root.compactLeft
    + (Math.min(root.compactLeft, launcherDrawer.x) - root.compactLeft)
      * root.launcherProgress
  readonly property real launcherAnimatedRight: root.compactRight
    + (Math.max(root.compactRight,
      launcherDrawer.x + launcherDrawer.width) - root.compactRight)
      * root.launcherProgress
  readonly property real expandedLeft: Math.min(root.compactLeft,
    root.workspaceAnimatedLeft, root.launcherAnimatedLeft)
  readonly property real expandedRight: Math.max(root.compactRight,
    root.workspaceAnimatedRight, root.launcherAnimatedRight)
  readonly property real leftCornerProgress: Math.max(
    workspaceDrawer.x <= root.compactLeft + 1 ? root.workspaceProgress : 0,
    launcherDrawer.x <= root.compactLeft + 1 ? root.launcherProgress : 0)
  readonly property real rightCornerProgress: Math.max(
    workspaceDrawer.x + workspaceDrawer.width >= root.compactRight - 1
      ? root.workspaceProgress : 0,
    launcherDrawer.x + launcherDrawer.width >= root.compactRight - 1
      ? root.launcherProgress : 0)

  Behavior on compactWidth {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  Region {
    id: islandInputRegion

    Region {
      item: island
      shape: RegionShape.Rect
      radius: BarMetrics.compactRadius
    }

    Region {
      x: island.x
      y: island.y + island.height - BarMetrics.compactRadius
      width: BarMetrics.compactRadius * root.leftCornerProgress
      height: BarMetrics.compactRadius * root.leftCornerProgress
    }

    Region {
      x: island.x + island.width - BarMetrics.compactRadius
      y: island.y + island.height - BarMetrics.compactRadius
      width: BarMetrics.compactRadius * root.rightCornerProgress
      height: BarMetrics.compactRadius * root.rightCornerProgress
    }

    Region {
      x: workspaceDrawer.visibleLeft
      y: workspaceDrawer.y
      width: workspaceDrawer.visibleWidth
      height: workspaceDrawer.inputHeight
      radius: workspaceDrawer.cardRadius
    }

    Region {
      x: workspaceDrawer.visibleLeft
      y: workspaceDrawer.y
      width: Math.min(workspaceDrawer.cardRadius,
        workspaceDrawer.visibleWidth)
      height: Math.min(workspaceDrawer.cardRadius,
        workspaceDrawer.inputHeight)
    }

    Region {
      x: workspaceDrawer.visibleLeft + Math.max(0,
        workspaceDrawer.visibleWidth - workspaceDrawer.cardRadius)
      y: workspaceDrawer.y
      width: Math.min(workspaceDrawer.cardRadius,
        workspaceDrawer.visibleWidth)
      height: Math.min(workspaceDrawer.cardRadius,
        workspaceDrawer.inputHeight)
    }

    Region {
      x: launcherDrawer.visibleLeft
      y: launcherDrawer.y
      width: launcherDrawer.visibleWidth
      height: launcherDrawer.inputHeight
      radius: launcherDrawer.cardRadius
    }

    Region {
      x: launcherDrawer.visibleLeft
      y: launcherDrawer.y
      width: Math.min(launcherDrawer.cardRadius,
        launcherDrawer.visibleWidth)
      height: Math.min(launcherDrawer.cardRadius,
        launcherDrawer.inputHeight)
    }

    Region {
      x: launcherDrawer.visibleLeft + Math.max(0,
        launcherDrawer.visibleWidth - launcherDrawer.cardRadius)
      y: launcherDrawer.y
      width: Math.min(launcherDrawer.cardRadius,
        launcherDrawer.visibleWidth)
      height: Math.min(launcherDrawer.cardRadius,
        launcherDrawer.inputHeight)
    }
  }

  Rectangle {
    id: island

    x: root.expandedLeft
    y: BarMetrics.compactTopOffset
    width: root.expandedRight - root.expandedLeft
    height: BarMetrics.compactHeight
    topLeftRadius: BarMetrics.compactRadius
    topRightRadius: BarMetrics.compactRadius
    bottomLeftRadius: BarMetrics.compactRadius
      * (1 - root.leftCornerProgress)
    bottomRightRadius: BarMetrics.compactRadius
      * (1 - root.rightCornerProgress)
    color: Theme.barSurface
    border.width: 1
    border.color: Theme.highlightMed

    Row {
      id: compactRow

      x: root.compactLeft - island.x
        + BarMetrics.compactHorizontalPadding
      anchors.verticalCenter: parent.verticalCenter
      spacing: BarMetrics.compactItemGap

      PowerMenu {}

      WorkspaceSwitcher {
        id: workspaceSwitcher

        monitor: root.monitor
        screen: root.screen
        drawerBlocked: root.launcherTarget
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

  WorkspaceDrawer {
    id: workspaceDrawer

    z: 1
    switcher: workspaceSwitcher
    monitor: root.monitor
    screen: root.screen
    anchorCenterX: root.compactLeft + workspaceSwitcher.mapToItem(
      compactRow, workspaceSwitcher.width / 2, 0).x
    islandLeft: root.compactLeft
    islandRight: root.compactRight
    surfaceLeft: island.x
    surfaceRight: island.x + island.width
    y: island.y + island.height - 1
  }

  LauncherDrawer {
    id: launcherDrawer

    z: 2
    service: root.launcherService
    screen: root.screen
    screenActive: root.focusedScreen
    anchorCenterX: root.compactLeft + launcherButton.mapToItem(
      compactRow, launcherButton.width / 2, 0).x
    islandLeft: root.compactLeft
    islandRight: root.compactRight
    surfaceLeft: island.x
    surfaceRight: island.x + island.width
    y: island.y + island.height - 1
  }

  Rectangle {
    id: workspaceSeam

    visible: workspaceDrawer.visible
    x: Math.max(workspaceDrawer.visibleLeft, island.x) + 1
    y: island.y + island.height - 2
    width: Math.max(0,
      Math.min(workspaceDrawer.visibleRight, island.x + island.width)
        - workspaceSeam.x - 1)
    height: Math.min(3, workspaceDrawer.visibleHeight + 2)
    color: Theme.barSurface
    z: 3
  }

  Rectangle {
    id: launcherSeam

    visible: launcherDrawer.visible
    x: Math.max(launcherDrawer.visibleLeft, island.x) + 1
    y: island.y + island.height - 2
    width: Math.max(0,
      Math.min(launcherDrawer.visibleRight, island.x + island.width)
        - launcherSeam.x - 1)
    height: Math.min(3, launcherDrawer.visibleHeight + 2)
    color: Theme.barSurface
    z: 4
  }

  onLauncherTargetChanged: {
    if (root.launcherTarget)
      workspaceSwitcher.closeDrawer();
  }
}
