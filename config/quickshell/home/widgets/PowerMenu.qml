import QtQuick
import Quickshell.Io
import qs.components
import qs.config
import qs.theme

Item {
  id: root

  readonly property bool open: menuHover.hovered

  implicitWidth: home.implicitWidth + actionDrawer.width
  implicitHeight: BarMetrics.height

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

    BarPill {
      id: home
      implicitWidth: 40
      hovered: homeHover.hovered

      Text {
        anchors.centerIn: parent
        color: Theme.accent
        font.family: Theme.iconFont
        font.pixelSize: 18
        text: ""
      }

      HoverHandler {
        id: homeHover
      }
    }

    Item {
      id: actionDrawer
      clip: true
      width: root.open ? actionsPill.implicitWidth : 0
      height: BarMetrics.height

      Behavior on width {
        NumberAnimation {
          duration: BarMetrics.animationDuration
        }
      }

      BarPill {
        id: actionsPill
        anchors.left: parent.left
        implicitWidth: actionsRow.implicitWidth

        Row {
          id: actionsRow
          anchors.centerIn: parent
          spacing: 0

          IconButton {
            icon: ""
            onClicked: lockProcess.startDetached()
          }
          IconButton {
            icon: ""
            onClicked: logoutProcess.startDetached()
          }
          IconButton {
            icon: ""
            onClicked: rebootProcess.startDetached()
          }
          IconButton {
            icon: ""
            onClicked: shutdownProcess.startDetached()
          }
        }
      }
    }
  }
}
