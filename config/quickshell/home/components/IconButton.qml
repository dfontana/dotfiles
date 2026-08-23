import QtQuick
import qs.config
import qs.theme

Item {
  id: root

  required property string icon
  property int iconSize: 14
  signal clicked

  implicitWidth: BarMetrics.iconButtonWidth
  implicitHeight: BarMetrics.height

  Rectangle {
    anchors.fill: parent
    color: buttonMouse.containsMouse ? Theme.hover : "transparent"
    radius: height / 2

    Behavior on color {
      ColorAnimation {
        duration: BarMetrics.animationDuration
      }
    }
  }

  Text {
    anchors.centerIn: parent
    color: Theme.accent
    font.family: Theme.iconFont
    font.pixelSize: root.iconSize
    text: root.icon
  }

  MouseArea {
    id: buttonMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
