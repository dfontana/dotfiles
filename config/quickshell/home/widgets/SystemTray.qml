import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config
import qs.theme

Item {
  id: root

  required property var hostWindow

  visible: trayRow.implicitWidth > 0
  implicitWidth: trayRow.implicitWidth
  implicitHeight: BarMetrics.compactSlotSize

  Row {
    id: trayRow

    anchors.centerIn: parent
    spacing: BarMetrics.compactItemGap

    Repeater {
      model: SystemTray.items

      Item {
        id: traySlot

        required property var modelData
        implicitWidth: BarMetrics.compactSlotSize
        implicitHeight: BarMetrics.compactSlotSize

        Item {
          id: trayInput

          width: 24
          height: 24
          anchors.centerIn: parent

          Rectangle {
            anchors.fill: parent
            radius: 12
            color: trayMouse.containsMouse ? Theme.hover : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: BarMetrics.compactHoverDuration
              }
            }
          }

          IconImage {
            anchors.centerIn: parent
            implicitSize: 20
            source: traySlot.modelData.icon
            opacity: traySlot.modelData.status === Status.Passive ? 0.55 : 1
          }

          MouseArea {
            id: trayMouse

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) {
                if (traySlot.modelData.hasMenu) {
                  const anchor = trayInput.mapToItem(null, 0, trayInput.height);
                  traySlot.modelData.display(root.hostWindow, anchor.x, anchor.y);
                }
              } else {
                traySlot.modelData.activate();
              }
            }
          }
        }
      }
    }
  }
}
