import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.theme

Item {
  id: root

  required property var monitor

  visible: taskRow.implicitWidth > 0
  implicitWidth: taskRow.implicitWidth
  implicitHeight: BarMetrics.compactSlotSize

  function applicationIcon(appId) {
    const entry = DesktopEntries.heuristicLookup(appId);
    return Quickshell.iconPath(entry?.icon ?? "application-x-executable");
  }

  Row {
    id: taskRow

    anchors.centerIn: parent
    spacing: BarMetrics.compactItemGap

    Repeater {
      model: Hyprland.toplevels

      Item {
        id: taskItem

        required property var modelData
        visible: modelData.monitor === root.monitor
        implicitWidth: BarMetrics.compactSlotSize
        implicitHeight: BarMetrics.compactSlotSize

        Rectangle {
          anchors.fill: parent
          radius: BarMetrics.compactHoverRadius
          color: taskMouse.containsMouse ? Theme.hover : "transparent"

          Behavior on color {
            ColorAnimation {
              duration: BarMetrics.compactHoverDuration
            }
          }
        }

        IconImage {
          anchors.centerIn: parent
          implicitSize: 20
          source: taskItem.modelData.wayland
            ? root.applicationIcon(taskItem.modelData.wayland.appId)
            : ""
        }

        MouseArea {
          id: taskMouse

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (taskItem.modelData.wayland)
              taskItem.modelData.wayland.activate();
          }
        }
      }
    }
  }
}
