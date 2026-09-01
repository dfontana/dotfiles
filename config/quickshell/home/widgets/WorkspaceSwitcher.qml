import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.theme

Item {
  id: root

  required property var monitor
  required property var screen
  property var hoveredWorkspace: null
  property bool triggerHovered: false
  property bool drawerHovered: false
  property bool drawerBlocked: false
  property bool closePending: false
  readonly property bool surfaceRequested: !root.drawerBlocked
    && (root.triggerHovered || root.drawerHovered || root.closePending)
  readonly property var workspaces: root.monitor && Hyprland.workspaces
    && Hyprland.workspaces.values
    ? Hyprland.workspaces.values.slice()
      .filter(workspace => workspace.monitor === root.monitor
        || Boolean(workspace.monitor && root.monitor
          && workspace.monitor.name === root.monitor.name))
      .sort((left, right) => left.id - right.id)
    : []
  readonly property var activeWorkspace: {
    const active = root.workspaces.find(workspace => workspace.active);
    if (active)
      return active;

    const monitorActive = root.monitor ? root.monitor.activeWorkspace : null;
    return root.workspaces.find(workspace => monitorActive
      && (workspace === monitorActive || workspace.id === monitorActive.id))
      ?? null;
  }

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
    if (root.drawerBlocked || !root.activeWorkspace)
      return;

    closeDrawerTimer.stop();
    root.closePending = false;
    root.hoveredWorkspace = root.activeWorkspace;
    root.triggerHovered = true;
  }

  function leaveWorkspace() {
    root.triggerHovered = false;
    root.scheduleClose();
  }

  function enterDrawer() {
    if (root.drawerBlocked)
      return;

    closeDrawerTimer.stop();
    root.closePending = false;
    root.drawerHovered = true;
    if (!root.hoveredWorkspace
        || !root.workspaces.includes(root.hoveredWorkspace))
      root.hoveredWorkspace = root.activeWorkspace;
  }

  function leaveDrawer() {
    root.drawerHovered = false;
    root.scheduleClose();
  }

  function scheduleClose() {
    if (!root.triggerHovered && !root.drawerHovered) {
      root.closePending = true;
      closeDrawerTimer.restart();
    }
  }

  function closeDrawer() {
    closeDrawerTimer.stop();
    root.closePending = false;
    root.hoveredWorkspace = null;
    root.triggerHovered = false;
    root.drawerHovered = false;
  }

  onDrawerBlockedChanged: {
    if (root.drawerBlocked)
      root.closeDrawer();
  }

  onWorkspacesChanged: {
    if (root.workspaces.length === 0) {
      root.closeDrawer();
      return;
    }

    if (root.hoveredWorkspace
        && !root.workspaces.includes(root.hoveredWorkspace)) {
      if (root.surfaceRequested && root.activeWorkspace)
        root.hoveredWorkspace = root.activeWorkspace;
      else
        root.closeDrawer();
    }
  }

  onActiveWorkspaceChanged: {
    if (!root.surfaceRequested)
      return;

    if (!root.activeWorkspace) {
      if (!root.drawerHovered)
        root.closeDrawer();
      else
        root.hoveredWorkspace = null;
    } else if (root.triggerHovered && !root.drawerHovered) {
      root.hoveredWorkspace = root.activeWorkspace;
    }
  }

  Timer {
    id: closeDrawerTimer

    interval: 180
    repeat: false
    onTriggered: {
      if (!root.triggerHovered && !root.drawerHovered)
        root.closeDrawer();
      else
        root.closePending = false;
    }
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
