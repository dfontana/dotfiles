import QtQuick
import qs.config
import qs.theme

Rectangle {
  id: root

  property bool hovered: false
  property color normalColor: Theme.barSurface
  property color hoverColor: Theme.hover

  implicitHeight: BarMetrics.height
  radius: height / 2
  color: hovered ? hoverColor : normalColor

  Behavior on color {
    ColorAnimation {
      duration: BarMetrics.animationDuration
    }
  }
}
