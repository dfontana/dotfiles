pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.theme

Item {
  id: root

  required property var switcher
  required property var monitor
  required property var screen
  property real anchorCenterX: 0

  readonly property var workspaces: root.switcher ? root.switcher.workspaces : []
  readonly property bool targetOpen: Boolean(root.switcher
    && root.switcher.surfaceRequested
    && root.workspaces.length > 0)
  property real openProgress: root.targetOpen ? 1 : 0

  readonly property int maxVisibleTiles: 4
  readonly property real tileWidth: 90
  readonly property real tileHeight: 76
  readonly property real tileGap: 6
  readonly property real cardPadding: 8
  readonly property real cardTop: 7
  readonly property real cardRadius: 12
  readonly property real connectorWidth: 22
  readonly property real connectorHeight: 8
  readonly property real controlWidth: 24
  readonly property real controlGap: 4
  readonly property bool overflowing: root.workspaces.length
    > root.maxVisibleTiles
  readonly property int visibleTileCount: Math.min(root.maxVisibleTiles,
    root.workspaces.length)
  readonly property real tileAreaWidth: root.visibleTileCount > 0
    ? root.visibleTileCount * root.tileWidth
      + (root.visibleTileCount - 1) * root.tileGap
    : 0
  readonly property real controlsWidth: root.overflowing
    ? root.controlWidth * 2 + root.controlGap * 2
    : 0
  readonly property real cardWidth: root.cardPadding * 2
    + root.tileAreaWidth + root.controlsWidth
  readonly property real cardHeight: root.cardPadding * 2 + root.tileHeight
  readonly property real fullHeight: root.cardTop + root.cardHeight
  readonly property real visibleHeight: root.fullHeight * root.openProgress
  readonly property real inputHeight: root.visible ? root.visibleHeight : 0
  readonly property real triggerCenterX: root.anchorCenterX > 0
    ? root.anchorCenterX : root.parent ? root.parent.width / 2 : 0
  readonly property real connectorX: Math.max(root.cardRadius,
    Math.min(root.width - root.cardRadius - root.connectorWidth,
      root.triggerCenterX - root.x - root.connectorWidth / 2))

  implicitWidth: root.cardWidth
  implicitHeight: root.fullHeight
  width: root.cardWidth
  height: root.fullHeight
  x: root.parent ? Math.max(0,
    Math.min(root.parent.width - root.width,
      root.triggerCenterX - root.width / 2)) : 0
  visible: root.targetOpen || root.openProgress > 0.001
  opacity: root.openProgress

  Behavior on openProgress {
    NumberAnimation {
      duration: root.targetOpen ? 180 : 120
      easing.type: root.targetOpen ? Easing.OutCubic : Easing.InCubic
    }
  }

  function focusWindow(toplevel: var, workspace: var): void {
    if (!toplevel)
      return;

    if (toplevel.wayland) {
      toplevel.wayland.activate();
      return;
    }

    const address = toplevel.address;
    if (!address) {
      if (workspace)
        workspace.activate();
      return;
    }

    let normalizedAddress = address.trim();
    if (normalizedAddress.startsWith("address:"))
      normalizedAddress = normalizedAddress.slice("address:".length);
    if (!normalizedAddress.startsWith("0x"))
      normalizedAddress = `0x${normalizedAddress}`;

    const reference = `address:${normalizedAddress}`;
    Hyprland.dispatch(Hyprland.usingLua
      ? `hl.dsp.focus({ window = "${reference}" })`
      : `focuswindow ${reference}`);
  }

  function clampScroll(): void {
    const maximum = Math.max(0,
      workspaceList.contentWidth - workspaceList.width);
    if (workspaceList.contentX > maximum)
      workspaceList.contentX = maximum;
  }

  function scrollBy(offset: int): void {
    const maximum = Math.max(0,
      workspaceList.contentWidth - workspaceList.width);
    workspaceList.contentX = Math.max(0, Math.min(maximum,
      workspaceList.contentX + offset * (root.tileWidth + root.tileGap)));
  }

  function revealWorkspace(workspace: var): void {
    if (!workspace || !root.overflowing)
      return;

    const index = root.workspaces.indexOf(workspace);
    if (index >= 0)
      workspaceList.positionViewAtIndex(index, ListView.Contain);
  }

  Item {
    id: revealClip

    width: root.width
    height: root.visibleHeight
    clip: true

    HoverHandler {
      id: drawerHover

      onHoveredChanged: {
        if (!root.switcher)
          return;
        if (hovered)
          root.switcher.enterDrawer();
        else
          root.switcher.leaveDrawer();
      }
    }

    Rectangle {
      id: card

      y: root.cardTop
      width: root.width
      height: root.cardHeight
      radius: root.cardRadius
      color: Theme.overlay
      border.width: 1
      border.color: Theme.highlightMed

      Rectangle {
        id: previousButton

        visible: root.overflowing
        x: root.cardPadding
        y: root.cardPadding
        width: root.controlWidth
        height: root.tileHeight
        radius: 8
        color: previousMouse.containsMouse
          ? Theme.highlightHigh : Theme.surface
        opacity: workspaceList.contentX > 0.5 ? 1 : 0.45

        Behavior on color {
          ColorAnimation {
            duration: 100
          }
        }

        Text {
          anchors.centerIn: parent
          color: Theme.text
          font.family: Theme.iconFont
          font.pixelSize: 15
          text: ""
        }

        MouseArea {
          id: previousMouse

          anchors.fill: parent
          enabled: workspaceList.contentX > 0.5
          hoverEnabled: enabled
          cursorShape: Qt.PointingHandCursor
          onClicked: root.scrollBy(-1)
        }
      }

      ListView {
        id: workspaceList

        x: root.cardPadding + (root.overflowing
          ? root.controlWidth + root.controlGap : 0)
        y: root.cardPadding
        width: root.tileAreaWidth
        height: root.tileHeight
        spacing: root.tileGap
        clip: true
        orientation: ListView.Horizontal
        interactive: root.overflowing
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
          values: root.workspaces
        }

        delegate: Item {
          id: workspaceTile

          required property var modelData
          required property int index
          readonly property bool active: Boolean(modelData
            && (modelData.active || (root.switcher
              && root.switcher.activeWorkspace
              && (root.switcher.activeWorkspace === modelData
                || root.switcher.activeWorkspace.id === modelData.id))))
          readonly property bool selected: Boolean(root.switcher
            && root.switcher.hoveredWorkspace === modelData)
          readonly property var windows: {
            if (!workspaceTile.modelData
                || !workspaceTile.modelData.toplevels)
              return [];

            return workspaceTile.modelData.toplevels.values.filter(toplevel => {
              const ipc = toplevel.lastIpcObject;
              return ipc && ipc.mapped;
            });
          }

          width: root.tileWidth
          height: root.tileHeight

          Rectangle {
            anchors.fill: parent
            radius: 10
            color: workspaceTile.selected
              ? Theme.highlightHigh
              : workspaceTile.active ? Theme.highlightLow : Theme.surface
            border.width: workspaceTile.active ? 2 : 1
            border.color: workspaceTile.active
              ? Theme.active
              : workspaceTile.selected ? Theme.accent : Theme.highlightMed

            Behavior on color {
              ColorAnimation {
                duration: 100
              }
            }

            Behavior on border.color {
              ColorAnimation {
                duration: 100
              }
            }
          }

          Row {
            x: 8
            y: 6
            width: parent.width - 16
            spacing: 5

            Text {
              width: parent.width - windowCount.implicitWidth - 5
              color: Theme.text
              font.pixelSize: 13
              font.weight: Font.DemiBold
              text: workspaceTile.modelData
                ? String(workspaceTile.modelData.name
                  || workspaceTile.modelData.id)
                : ""
              elide: Text.ElideRight
            }

            Text {
              id: windowCount

              color: Theme.subtle
              font.pixelSize: 10
              text: workspaceTile.windows.length
            }
          }

          Rectangle {
            id: previewStrip

            x: 6
            y: 28
            width: parent.width - 12
            height: parent.height - y - 6
            radius: 6
            color: Theme.base
            opacity: 0.9
            z: 1

            Text {
              anchors.centerIn: parent
              color: Theme.subtle
              font.pixelSize: 9
              text: "empty"
              visible: workspaceTile.windows.length === 0
            }

            Repeater {
              model: Math.min(workspaceTile.windows.length, 3)

              delegate: Rectangle {
                id: windowMiniature

                required property int index
                readonly property var toplevel: workspaceTile.windows[index]
                readonly property var ipc: toplevel
                  ? (toplevel.lastIpcObject || {}) : ({})
                readonly property string appId: toplevel && toplevel.wayland
                  && toplevel.wayland.appId
                  ? toplevel.wayland.appId : String(ipc.class || "")

                x: 4 + index * (width + 3)
                y: 4
                width: Math.max(12,
                  (parent.width - 8 - (Math.min(workspaceTile.windows.length, 3)
                    - 1) * 3) / Math.min(workspaceTile.windows.length, 3))
                height: parent.height - 8
                radius: 3
                color: Theme.highlightLow
                border.width: 1
                border.color: toplevel && toplevel.urgent
                  ? Theme.love : Theme.highlightHigh

                IconImage {
                  anchors.centerIn: parent
                  implicitSize: Math.min(18, parent.height - 6)
                  source: root.applicationIcon(windowMiniature.appId)
                  opacity: 0.9
                }

                MouseArea {
                  anchors.fill: parent
                  z: 2
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.focusWindow(windowMiniature.toplevel,
                    workspaceTile.modelData)
                }
              }
            }

            Text {
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.rightMargin: 3
              anchors.bottomMargin: 2
              color: Theme.text
              font.pixelSize: 8
              text: "+" + (workspaceTile.windows.length - 3)
              visible: workspaceTile.windows.length > 3
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
              if (root.switcher) {
                root.switcher.hoveredWorkspace = workspaceTile.modelData;
                root.switcher.enterDrawer();
              }
            }
            onClicked: {
              if (workspaceTile.modelData
                  && root.workspaces.includes(workspaceTile.modelData)) {
                root.switcher.hoveredWorkspace = workspaceTile.modelData;
                workspaceTile.modelData.activate();
              }
            }
          }
        }
      }

      Rectangle {
        id: nextButton

        visible: root.overflowing
        x: root.cardPadding + root.controlWidth + root.controlGap
          + root.tileAreaWidth + root.controlGap
        y: root.cardPadding
        width: root.controlWidth
        height: root.tileHeight
        radius: 8
        color: nextMouse.containsMouse ? Theme.highlightHigh : Theme.surface
        opacity: workspaceList.contentX
          < workspaceList.contentWidth - workspaceList.width - 0.5 ? 1 : 0.45

        Behavior on color {
          ColorAnimation {
            duration: 100
          }
        }

        Text {
          anchors.centerIn: parent
          color: Theme.text
          font.family: Theme.iconFont
          font.pixelSize: 15
          text: ""
        }

        MouseArea {
          id: nextMouse

          anchors.fill: parent
          enabled: workspaceList.contentX
            < workspaceList.contentWidth - workspaceList.width - 0.5
          hoverEnabled: enabled
          cursorShape: Qt.PointingHandCursor
          onClicked: root.scrollBy(1)
        }
      }
    }

    Rectangle {
      id: connector

      x: root.connectorX
      y: 0
      width: root.connectorWidth
      height: root.connectorHeight
      color: Theme.overlay
      z: 1
    }
  }

  function applicationIcon(appId: string): string {
    if (!appId)
      return Quickshell.iconPath("application-x-executable");

    const entry = DesktopEntries.heuristicLookup(appId);
    return Quickshell.iconPath(entry?.icon ?? "application-x-executable");
  }

  onTargetOpenChanged: {
    if (root.targetOpen && root.switcher && root.switcher.hoveredWorkspace)
      Qt.callLater(() => root.revealWorkspace(
        root.switcher.hoveredWorkspace));
  }

  onWorkspacesChanged: Qt.callLater(root.clampScroll)

  Connections {
    target: root.switcher

    function onActiveWorkspaceChanged(): void {
      if (root.targetOpen && root.switcher.activeWorkspace)
        Qt.callLater(() => root.revealWorkspace(root.switcher.activeWorkspace));
    }
  }
}
