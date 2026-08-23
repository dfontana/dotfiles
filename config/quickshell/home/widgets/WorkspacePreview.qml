import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme

PopupWindow {
  id: root

  required property var outputScreen
  property var workspace: null
  property Item anchorItem: null
  readonly property bool hovered: popupHover.hovered
  readonly property int cardWidth: 250
  readonly property int cardHeight: 180
  readonly property int cardGap: 8

  visible: false
  color: "transparent"
  implicitWidth: root.cardWidth + root.cardGap * 2
  implicitHeight: root.cardHeight + root.cardGap * 2

  anchor {
    item: root.anchorItem
    edges: Edges.Bottom | Edges.Left
    gravity: Edges.Bottom | Edges.Right
    adjustment: PopupAdjustment.All
    margins.top: root.cardGap
  }

  function applicationIcon(appId) {
    if (!appId)
      return Quickshell.iconPath("application-x-executable");

    const entry = DesktopEntries.heuristicLookup(appId);
    return Quickshell.iconPath(entry?.icon ?? "application-x-executable");
  }

  function focusWindow(toplevel) {
    if (toplevel.wayland) {
      toplevel.wayland.activate();
      return;
    }

    const address = toplevel.address;
    if (!address) {
      root.workspace.activate();
      return;
    }

    let normalizedAddress = address.trim();
    if (normalizedAddress.startsWith("address:"))
      normalizedAddress = normalizedAddress.slice("address:".length);
    if (!normalizedAddress.startsWith("0x"))
      normalizedAddress = `0x${normalizedAddress}`;

    const reference = `address:${normalizedAddress}`;
    Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ window = "${reference}" })` : `focuswindow ${reference}`);
  }

  Item {
    anchors.fill: parent

    HoverHandler {
      id: popupHover
    }

    Rectangle {
      anchors.fill: parent
      color: Theme.barSurface
      radius: 12
      border.color: Theme.highlightMed
      border.width: 1
    }

    Rectangle {
      id: card

      readonly property var windows: {
        if (!root.workspace || !root.workspace.toplevels)
          return [];

        return root.workspace.toplevels.values.filter(toplevel => {
          const ipc = toplevel.lastIpcObject;
          return ipc && ipc.mapped;
        });
      }

      anchors.fill: parent
      anchors.margins: root.cardGap
      radius: 9
      color: Theme.overlay
      border.color: Theme.accent
      border.width: 2
      clip: true

      MouseArea {
        anchors.fill: parent
        z: 1
        enabled: root.workspace !== null
        cursorShape: Qt.PointingHandCursor
        onClicked: root.workspace.activate()
      }

      Row {
        id: cardHeader
        x: 10
        y: 7
        width: parent.width - 20
        spacing: 6
        z: 2

        Text {
          color: Theme.text
          font.family: Theme.iconFont
          font.pixelSize: 14
          font.weight: Font.DemiBold
          text: root.workspace ? (root.workspace.name || root.workspace.id) : ""
        }

        Text {
          color: Theme.subtle
          font.family: Theme.iconFont
          font.pixelSize: 11
          text: card.windows.length === 1 ? "1 window" : `${card.windows.length} windows`
          elide: Text.ElideRight
        }
      }

      Item {
        id: windowCanvas
        x: 8
        y: cardHeader.y + cardHeader.height + 5
        width: parent.width - 16
        height: parent.height - y - 8
        clip: true
        z: 2

        Rectangle {
          anchors.fill: parent
          color: Theme.base
          radius: 6
          opacity: 0.9
        }

        Text {
          anchors.centerIn: parent
          color: Theme.subtle
          font.family: Theme.iconFont
          font.pixelSize: 11
          text: "Empty workspace"
          visible: card.windows.length === 0
        }

        Repeater {
          model: card.windows

          Item {
            id: windowPreview

            required property var modelData
            readonly property var ipc: modelData.lastIpcObject || ({})
            readonly property var position: ipc.at || [0, 0]
            readonly property var windowSize: ipc.size || [1, 1]
            readonly property string appId: modelData.wayland && modelData.wayland.appId ? modelData.wayland.appId : (ipc.class || "")
            readonly property string title: modelData.title || ipc.title || ipc.class || "Unknown window"
            readonly property real monitorWidth: Math.max(1, root.outputScreen ? root.outputScreen.width : 1)
            readonly property real monitorHeight: Math.max(1, root.outputScreen ? root.outputScreen.height : 1)
            readonly property real monitorX: root.outputScreen ? root.outputScreen.x : 0
            readonly property real monitorY: root.outputScreen ? root.outputScreen.y : 0
            readonly property real scale: Math.min(windowCanvas.width / monitorWidth, windowCanvas.height / monitorHeight)
            readonly property real viewportX: (windowCanvas.width - monitorWidth * scale) / 2
            readonly property real viewportY: (windowCanvas.height - monitorHeight * scale) / 2
            readonly property real naturalX: viewportX + (Number(position[0] || 0) - monitorX) * scale
            readonly property real naturalY: viewportY + (Number(position[1] || 0) - monitorY) * scale
            readonly property real naturalWidth: Math.max(8, Number(windowSize[0] || 1) * scale)
            readonly property real naturalHeight: Math.max(8, Number(windowSize[1] || 1) * scale)

            x: Math.max(0, Math.min(windowCanvas.width - 8, naturalX))
            y: Math.max(0, Math.min(windowCanvas.height - 8, naturalY))
            width: Math.max(8, Math.min(windowCanvas.width - x, naturalWidth))
            height: Math.max(8, Math.min(windowCanvas.height - y, naturalHeight))
            z: modelData.activated ? 2 : 1

            Rectangle {
              anchors.fill: parent
              color: Theme.highlightLow
              radius: 4
              border.color: modelData.urgent ? Theme.love : Theme.highlightHigh
              border.width: modelData.urgent ? 2 : 1
            }

            ScreencopyView {
              id: screenshot
              anchors.fill: parent
              z: 1
              captureSource: windowPreview.modelData.wayland || null
              live: false
              paintCursor: false
              opacity: hasContent ? 1 : 0

              Component.onCompleted: Qt.callLater(() => {
                if (screenshot.captureSource)
                  screenshot.captureFrame();
              })
            }

            Column {
              anchors.centerIn: parent
              width: parent.width - 8
              spacing: 2
              z: 2
              visible: !screenshot.hasContent

              IconImage {
                anchors.horizontalCenter: parent.horizontalCenter
                implicitSize: 24
                source: root.applicationIcon(windowPreview.appId)
              }

              Text {
                width: parent.width
                color: Theme.text
                font.family: Theme.iconFont
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 2
                text: windowPreview.title
              }
            }

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: 22
              z: 3
              color: Theme.base
              visible: screenshot.hasContent && parent.height > 28

              Row {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                spacing: 4

                IconImage {
                  anchors.verticalCenter: parent.verticalCenter
                  implicitSize: 14
                  source: root.applicationIcon(windowPreview.appId)
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - 18
                  color: Theme.text
                  font.family: Theme.iconFont
                  font.pixelSize: 9
                  elide: Text.ElideRight
                  text: windowPreview.title
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              z: 4
              cursorShape: Qt.PointingHandCursor
              onClicked: root.focusWindow(windowPreview.modelData)
            }
          }
        }
      }
    }
  }
}
