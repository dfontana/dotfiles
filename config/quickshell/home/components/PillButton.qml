import QtQuick
import qs.components
import qs.config

Item {
  id: root

  property bool hovered: buttonMouse.containsMouse
  signal clicked

  default property alias content: contentHost.data

  implicitHeight: BarMetrics.height

  BarPill {
    anchors.fill: parent
    hovered: root.hovered
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
