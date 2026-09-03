pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.config
import qs.theme

Item {
  id: root

  required property var service
  required property var screen
  property real anchorCenterX: 0
  property real islandLeft: 0
  property real islandRight: 0
  property real surfaceLeft: root.islandLeft
  property real surfaceRight: root.islandRight

  readonly property bool routedHere: Boolean(root.service
    && root.screen && root.service.sameScreen(root.service.routedScreen,
      root.screen))
  readonly property bool targetOpen: Boolean(root.routedHere
    && root.service.stackVisible)
  property real openProgress: root.targetOpen ? 1 : 0

  readonly property real drawerPadding: 8
  readonly property real drawerHeaderHeight: 32
  readonly property real cardRadius: 12
  readonly property real edgeMargin: 12
  readonly property real minimumWidth: 180
  readonly property real maximumWidth: 420
  readonly property real availableWidth: root.parent
    ? root.parent.width : root.maximumWidth
  readonly property real cardWidth: Math.max(root.minimumWidth,
    Math.min(root.maximumWidth, root.availableWidth - root.edgeMargin * 2))
  readonly property real maximumHeight: root.screen
    ? Math.max(0, Math.min(480, root.screen.height * 0.5,
      root.screen.height - root.y - root.edgeMargin))
    : 0
  readonly property real cardContentHeight: cardList.contentItem
    ? cardList.contentItem.childrenRect.height : 0
  readonly property real drawerHeight: Math.min(root.maximumHeight,
    root.drawerPadding * 2 + root.drawerHeaderHeight
      + root.cardContentHeight)
  readonly property real fullHeight: root.drawerHeight
  readonly property real visibleHeight: root.height * root.openProgress
  readonly property real inputHeight: root.visible ? root.visibleHeight : 0
  readonly property bool overflowing: root.cardContentHeight
    > cardList.height + 1
  readonly property real triggerCenterX: root.anchorCenterX > 0
    ? root.anchorCenterX : root.availableWidth / 2
  readonly property bool alignLeft: root.triggerCenterX
    <= (root.islandLeft + root.islandRight) / 2
  readonly property real visibleLeft: Math.max(root.x, root.surfaceLeft)
  readonly property real visibleRight: Math.min(root.x + root.width,
    root.surfaceRight)
  readonly property real visibleWidth: Math.max(0,
    root.visibleRight - root.visibleLeft)
  readonly property bool pointerHovered: Boolean(root.targetOpen
    && drawerHover.hovered)

  implicitWidth: root.cardWidth
  implicitHeight: root.fullHeight
  width: root.cardWidth
  height: root.fullHeight
  x: Math.max(root.edgeMargin,
    Math.min(root.availableWidth - root.width - root.edgeMargin,
      root.alignLeft ? root.islandLeft : root.islandRight - root.width))
  visible: root.routedHere && (root.targetOpen || root.openProgress > 0.001)

  Behavior on height {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  Behavior on openProgress {
    NumberAnimation {
      duration: root.targetOpen ? 180 : 120
      easing.type: root.targetOpen ? Easing.OutCubic : Easing.InCubic
    }
  }

  Item {
    id: revealClip

    x: root.visibleLeft - root.x
    width: root.visibleWidth
    height: root.visibleHeight
    clip: true

    HoverHandler {
      id: drawerHover
    }

    Rectangle {
      anchors.fill: parent
      topLeftRadius: 0
      topRightRadius: 0
      bottomLeftRadius: root.cardRadius
      bottomRightRadius: root.cardRadius
      color: Theme.barSurface
      border.width: 1
      border.color: Theme.highlightMed
    }

    Item {
      id: contentLayer

      x: -revealClip.x
      width: root.width
      height: root.drawerHeight
      enabled: root.targetOpen

      Item {
        id: header

        x: root.drawerPadding
        y: root.drawerPadding
        width: parent.width - root.drawerPadding * 2
        height: root.drawerHeaderHeight
        visible: root.service && root.service.hasVisualRecords

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 4
          anchors.verticalCenter: parent.verticalCenter
          color: Theme.text
          font.pixelSize: 12
          font.weight: Font.DemiBold
          text: "Notifications"
        }

        PillButton {
          id: clearAllButton

          visible: root.service && root.service.hasNotifications
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: clearAllContent.implicitWidth + 18
          height: 24
          normalColor: Theme.surface
          hoverColor: Theme.highlightHigh
          radius: 6
          borderWidth: 1
          borderColor: Theme.highlightHigh
          onClicked: root.service.clearAll()

          Row {
            id: clearAllContent

            anchors.centerIn: parent
            spacing: 5

            Text {
              color: Theme.accent
              font.family: Theme.iconFont
              font.pixelSize: 13
              text: "󰆴"
            }

            Text {
              color: Theme.text
              font.pixelSize: 11
              font.weight: Font.Medium
              text: "Clear all"
            }
          }
        }
      }

      ListView {
        id: cardList

        x: root.drawerPadding
        y: root.drawerPadding + header.height
        width: parent.width - root.drawerPadding * 2
        height: Math.min(root.cardContentHeight,
          Math.max(0, root.maximumHeight - root.drawerPadding * 2
            - root.drawerHeaderHeight))
        contentHeight: root.cardContentHeight
        clip: true
        spacing: BarMetrics.gap
        interactive: root.overflowing
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
          values: root.service ? root.service.records : []
        }

        Behavior on contentY {
          NumberAnimation {
            duration: BarMetrics.animationDuration
            easing.type: Easing.OutCubic
          }
        }

        add: Transition {
          NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: 180
            easing.type: Easing.OutCubic
          }
        }

        displaced: Transition {
          NumberAnimation {
            property: "y"
            duration: 150
            easing.type: Easing.OutCubic
          }
        }

        remove: Transition {
          ParallelAnimation {
            NumberAnimation {
              property: "opacity"
              to: 0
              duration: 120
              easing.type: Easing.InCubic
            }
            NumberAnimation {
              property: "height"
              to: 0
              duration: 120
              easing.type: Easing.InCubic
            }
          }
        }

        delegate: NotificationCard {}

        ScrollBar.vertical: ScrollBar {
          policy: root.pointerHovered && root.overflowing
            ? ScrollBar.AlwaysOn
            : ScrollBar.AlwaysOff
          width: 4
          background: null

          contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: Theme.muted
          }
        }
      }
    }
  }

  function scrollToEnd() {
    Qt.callLater(() => {
      if (cardList.count > 0)
        cardList.positionViewAtEnd();
    });
  }

  onPointerHoveredChanged: {
    if (root.service)
      root.service.setStackHovered(root.pointerHovered);
    if (!root.pointerHovered)
      root.scrollToEnd();
  }

  Connections {
    target: root.service

    function onRecordAdded() {
      if (!root.pointerHovered)
        root.scrollToEnd();
    }
  }
}
