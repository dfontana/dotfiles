import QtQuick
import qs.config
import qs.theme

Item {
  id: root

  required property string icon
  property int iconSize: 16
  property color iconColor: Theme.text
  property bool interactive: true
  property bool indicatorVisible: false
  property color indicatorColor: Theme.accent
  property int acceptedButtons: Qt.LeftButton
  readonly property bool hovered: buttonMouse.containsMouse

  signal clicked(var mouse)

  implicitWidth: BarMetrics.compactSlotSize
  implicitHeight: BarMetrics.compactSlotSize

  Rectangle {
    anchors.fill: parent
    radius: BarMetrics.compactHoverRadius
    color: root.interactive && buttonMouse.containsMouse ? Theme.hover : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: BarMetrics.compactHoverDuration
      }
    }
  }

  Text {
    anchors.centerIn: parent
    color: root.iconColor
    font.family: Theme.iconFont
    font.pixelSize: root.iconSize
    text: root.icon
  }

  Rectangle {
    visible: root.indicatorVisible
    width: 4
    height: 4
    anchors.right: parent.right
    anchors.rightMargin: 3
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 3
    radius: 2
    color: root.indicatorColor
  }

  MouseArea {
    id: buttonMouse

    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: root.interactive
    acceptedButtons: root.acceptedButtons
    cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: mouse => root.clicked(mouse)
  }
}
