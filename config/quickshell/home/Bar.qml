import QtQuick
import Quickshell
import Quickshell.Hyprland
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
  implicitHeight: BarMetrics.compactFootprint
  mask: islandInputRegion
  surfaceFormat: {
    "opaque": false
  }

  anchors {
    top: true
    left: true
    right: true
  }

  readonly property var monitor: Hyprland.monitorFor(screen)
  readonly property bool primary: screen && screen.name === BarMetrics.primaryOutput

  Region {
    id: islandInputRegion

    item: island
    shape: RegionShape.Rect
    radius: BarMetrics.compactRadius
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
        icon: ""
        iconSize: 16
        iconColor: Theme.text
        onClicked: root.launcherService.toggleLauncher()
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
}
