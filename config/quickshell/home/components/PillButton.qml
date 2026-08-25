import QtQuick
import qs.components
import qs.config

Item {
  id: root

  property bool hovered: buttonMouse.containsMouse
  property alias normalColor: background.normalColor
  property alias hoverColor: background.hoverColor
  property alias radius: background.radius
  property color borderColor: "transparent"
  property real borderWidth: 0
  signal clicked

  default property alias content: contentHost.data

  implicitHeight: BarMetrics.height

  BarPill {
    id: background
    anchors.fill: parent
    hovered: root.hovered
    border.color: root.borderColor
    border.width: root.borderWidth
  }

  Item {
    id: contentHost
    anchors.fill: parent
  }

  MouseArea {
    id: buttonMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
