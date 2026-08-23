import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.components

BarPill {
  id: root

  required property var monitor

  visible: taskRow.implicitWidth > 0
  implicitWidth: taskRow.implicitWidth > 0 ? taskRow.implicitWidth + 20 : 0

  function applicationIcon(appId) {
    const entry = DesktopEntries.heuristicLookup(appId);
    return Quickshell.iconPath(entry?.icon ?? "application-x-executable");
  }

  Row {
    id: taskRow
    anchors.centerIn: parent
    spacing: 6

    Repeater {
      model: Hyprland.toplevels

      Item {
        required property var modelData
        visible: modelData.monitor === root.monitor
        implicitWidth: 24
        implicitHeight: 24

        IconImage {
          anchors.centerIn: parent
          implicitSize: 20
          source: modelData.wayland ? root.applicationIcon(modelData.wayland.appId) : ""
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (modelData.wayland)
              modelData.wayland.activate();
          }
        }
      }
    }
  }
}
