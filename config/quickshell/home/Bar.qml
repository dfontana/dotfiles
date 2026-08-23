import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.widgets

PanelWindow {
  id: root

  property var modelData

  screen: modelData
  color: "transparent"
  exclusiveZone: BarMetrics.height + BarMetrics.margin
  implicitHeight: BarMetrics.height
  surfaceFormat: {
    "opaque": false
  }

  anchors {
    top: true
    left: true
    right: true
  }

  margins {
    top: BarMetrics.margin
    left: BarMetrics.margin
    right: BarMetrics.margin
  }

  readonly property var monitor: Hyprland.monitorFor(screen)
  readonly property bool primary: screen && screen.name === BarMetrics.primaryOutput

  Item {
    anchors.fill: parent

    Row {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      spacing: BarMetrics.gap

      PowerMenu {}

      TaskList {
        monitor: root.monitor
      }

      SystemTray {
        hostWindow: root
      }
    }

    WorkspaceSwitcher {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      monitor: root.monitor
      screen: root.screen
    }

    StatusArea {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      outputName: root.screen ? root.screen.name : ""
      updatesEnabled: root.primary
    }
  }
}
