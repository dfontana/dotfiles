import QtQuick
import Quickshell.Io
import qs.components
import qs.config
import qs.theme

Item {
  id: root

  readonly property bool open: menuHover.hovered

  implicitWidth: powerButton.implicitWidth + actionDrawer.width
  implicitHeight: BarMetrics.compactSlotSize

  HoverHandler {
    id: menuHover
  }

  Process {
    id: lockProcess
    command: ["hyprlock"]
  }

  Process {
    id: logoutProcess
    command: ["hyprctl", "dispatch", "hl.dsp.exit()"]
  }

  Process {
    id: rebootProcess
    command: ["reboot"]
  }

  Process {
    id: shutdownProcess
    command: ["shutdown", "now"]
  }

  Row {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    spacing: 0

    CompactIconButton {
      id: powerButton

      icon: ""
      iconSize: 18
      iconColor: Theme.accent
    }

    Item {
      id: actionDrawer

      clip: true
      width: root.open
        ? BarMetrics.compactItemGap + actionsRow.implicitWidth
        : 0
      height: BarMetrics.compactSlotSize

      Behavior on width {
        NumberAnimation {
          duration: 180
          easing.type: Easing.OutCubic
        }
      }

      Row {
        id: actionsRow

        anchors.left: parent.left
        anchors.leftMargin: BarMetrics.compactItemGap
        spacing: BarMetrics.compactItemGap

        CompactIconButton {
          icon: ""
          iconColor: Theme.text
          onClicked: lockProcess.startDetached()
        }
        CompactIconButton {
          icon: ""
          iconColor: Theme.text
          onClicked: logoutProcess.startDetached()
        }
        CompactIconButton {
          icon: ""
          iconColor: Theme.text
          onClicked: rebootProcess.startDetached()
        }
        CompactIconButton {
          icon: ""
          iconColor: Theme.love
          onClicked: shutdownProcess.startDetached()
        }
      }
    }
  }
}
