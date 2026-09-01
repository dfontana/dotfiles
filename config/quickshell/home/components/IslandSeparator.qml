import QtQuick
import qs.config
import qs.theme

Item {
  implicitWidth: BarMetrics.compactSeparatorMargin * 2 + 1
  implicitHeight: BarMetrics.compactSlotSize

  Rectangle {
    width: 1
    height: BarMetrics.compactSeparatorHeight
    anchors.centerIn: parent
    color: Theme.highlightMed
  }
}
