import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.config
import qs.theme
import qs.widgets

BarPill {
  id: root

  required property var monitor
  required property var screen
  property var hoveredWorkspace: null
  property var hoveredSegment: null
  property bool triggerHovered: false
  readonly property var workspaces: root.monitor ? Hyprland.workspaces.values.slice().filter(workspace => workspace.monitor === root.monitor).sort((left, right) => left.id - right.id) : []

  visible: workspaceRow.implicitWidth > 0
  implicitWidth: workspaceRow.implicitWidth + 20

  function enterWorkspace(workspace, segment) {
    closePreviewTimer.stop()
    hoveredWorkspace = workspace
    hoveredSegment = segment
    triggerHovered = true
    workspacePreview.visible = true
    Qt.callLater(() => {
      if (root.hoveredSegment === segment)
        workspacePreview.anchor.updateAnchor()
    })
  }

  function leaveWorkspace(segment) {
    if (root.hoveredSegment !== segment)
      return

    triggerHovered = false
    closePreviewTimer.restart()
  }

  function closePreview() {
    closePreviewTimer.stop()
    workspacePreview.visible = false
    hoveredWorkspace = null
    hoveredSegment = null
    triggerHovered = false
  }

  Timer {
    id: closePreviewTimer
    interval: 180
    repeat: false

    onTriggered: {
      if (!root.triggerHovered && !workspacePreview.hovered)
        root.closePreview()
    }
  }

  Connections {
    target: workspacePreview

    function onHoveredChanged() {
      if (workspacePreview.hovered)
        closePreviewTimer.stop()
      else if (!root.triggerHovered && root.hoveredWorkspace !== null)
        closePreviewTimer.restart()
    }
  }

  WorkspacePreview {
    id: workspacePreview
    outputScreen: root.screen
    workspace: root.hoveredWorkspace
    anchorItem: root.hoveredSegment
  }

  Row {
    id: workspaceRow
    anchors.centerIn: parent
    spacing: 6

    Repeater {
      model: root.workspaces

      Rectangle {
        id: workspaceSegment

        required property var modelData
        readonly property bool active: modelData.active

        Component.onDestruction: {
          if (root.hoveredSegment === workspaceSegment)
            root.closePreview()
        }

        width: active ? 30 : 20
        height: 20
        radius: height / 2
        color: workspaceMouse.containsMouse ? Theme.hover : active ? Theme.active : Theme.text

        Behavior on color {
          ColorAnimation {
            duration: BarMetrics.animationDuration
          }
        }
        Behavior on width {
          NumberAnimation {
            duration: BarMetrics.animationDuration
          }
        }

        Text {
          anchors.centerIn: parent
          color: parent.active ? Theme.barSurface : Theme.accent
          font.family: Theme.iconFont
          font.pixelSize: 14
          font.weight: Font.DemiBold
          text: parent.modelData.id
        }

        MouseArea {
          id: workspaceMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.enterWorkspace(parent.modelData, parent)
          onExited: root.leaveWorkspace(parent)
          onClicked: parent.modelData.activate()
        }
      }
    }
  }
}
