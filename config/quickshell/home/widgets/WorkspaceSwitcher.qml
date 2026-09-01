import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.theme
import qs.widgets

Item {
  id: root

  required property var monitor
  required property var screen
  property var hoveredWorkspace: null
  property bool triggerHovered: false
  readonly property var workspaces: root.monitor
    ? Hyprland.workspaces.values.slice()
      .filter(workspace => workspace.monitor === root.monitor)
      .sort((left, right) => left.id - right.id)
    : []
  readonly property var activeWorkspace: root.workspaces.find(workspace => workspace.active) ?? null

  implicitWidth: workspaceButton.implicitWidth
  implicitHeight: workspaceButton.implicitHeight

  function activateRelative(offset) {
    if (root.workspaces.length < 2 || !root.activeWorkspace)
      return;

    const activeIndex = root.workspaces.indexOf(root.activeWorkspace);
    const targetIndex = (activeIndex + offset + root.workspaces.length)
      % root.workspaces.length;
    root.workspaces[targetIndex].activate();
  }

  function enterWorkspace() {
    if (!root.activeWorkspace)
      return;

    closePreviewTimer.stop();
    root.hoveredWorkspace = root.activeWorkspace;
    root.triggerHovered = true;
    workspacePreview.visible = true;
    Qt.callLater(() => workspacePreview.anchor.updateAnchor());
  }

  function leaveWorkspace() {
    root.triggerHovered = false;
    closePreviewTimer.restart();
  }

  function closePreview() {
    closePreviewTimer.stop();
    workspacePreview.visible = false;
    root.hoveredWorkspace = null;
    root.triggerHovered = false;
  }

  onWorkspacesChanged: {
    if (root.hoveredWorkspace
        && !root.workspaces.includes(root.hoveredWorkspace))
      root.closePreview();
  }

  onActiveWorkspaceChanged: {
    if (!root.triggerHovered)
      return;

    if (!root.activeWorkspace)
      root.closePreview();
    else
      root.hoveredWorkspace = root.activeWorkspace;
  }

  Timer {
    id: closePreviewTimer

    interval: 180
    repeat: false
    onTriggered: {
      if (!root.triggerHovered && !workspacePreview.hovered)
        root.closePreview();
    }
  }

  Connections {
    target: workspacePreview

    function onHoveredChanged() {
      if (workspacePreview.hovered)
        closePreviewTimer.stop();
      else if (!root.triggerHovered && root.hoveredWorkspace !== null)
        closePreviewTimer.restart();
    }
  }

  WorkspacePreview {
    id: workspacePreview

    outputScreen: root.screen
    workspace: root.hoveredWorkspace
    anchorItem: workspaceButton
  }

  CompactIconButton {
    id: workspaceButton

    icon: "󰍹"
    iconSize: 17
    iconColor: root.activeWorkspace ? Theme.active : Theme.muted
    interactive: root.activeWorkspace !== null
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onHoveredChanged: {
      if (hovered)
        root.enterWorkspace();
      else
        root.leaveWorkspace();
    }
    onClicked: mouse => root.activateRelative(
      mouse.button === Qt.RightButton ? -1 : 1)
  }
}
