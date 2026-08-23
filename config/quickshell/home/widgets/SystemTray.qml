import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components

BarPill {
  id: root

  required property var hostWindow

  visible: trayRow.implicitWidth > 0
  implicitWidth: trayRow.implicitWidth > 0 ? trayRow.implicitWidth + 20 : 0

  Row {
    id: trayRow
    anchors.centerIn: parent
    spacing: 5

    Repeater {
      model: SystemTray.items

      Item {
        id: trayItem
        required property var modelData
        implicitWidth: 24
        implicitHeight: 24

        IconImage {
          anchors.centerIn: parent
          implicitSize: 20
          source: modelData.icon
          opacity: modelData.status === Status.Passive ? 0.55 : 1
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          onClicked: mouse => {
            if (mouse.button === Qt.RightButton && modelData.hasMenu) {
              modelData.display(root.hostWindow, root.x + trayItem.x, trayItem.y + trayItem.height);
            } else {
              modelData.activate();
            }
          }
        }
      }
    }
  }
}
