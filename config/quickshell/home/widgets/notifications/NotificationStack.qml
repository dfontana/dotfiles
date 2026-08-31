import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.theme

PanelWindow {
  id: root

  required property var service
  readonly property real topMargin: BarMetrics.margin + BarMetrics.height + BarMetrics.gap
  readonly property real drawerPadding: 8
  readonly property real drawerHeaderHeight: 32
  readonly property real cardContentHeight: cardList.contentItem
    ? cardList.contentItem.childrenRect.height : 0
  readonly property real maxHeight: root.screen
    ? Math.max(0, root.screen.height - root.topMargin - BarMetrics.margin)
    : 0
  readonly property real drawerHeight: Math.min(root.maxHeight,
    root.drawerPadding * 2 + root.drawerHeaderHeight
    + root.cardContentHeight)
  readonly property bool overflowing: root.cardContentHeight > cardList.height + 1
  readonly property bool pointerHovered: Boolean(root.service
    && root.service.surfaceVisible
    && root.service.stackVisible
    && stackHover.hovered)
  readonly property real visibleContentX: Math.max(0,
    Math.min(width, animatedStack.x))

  screen: root.service ? root.service.routedScreen : null
  visible: Boolean(root.service && root.service.surfaceVisible)
  color: "transparent"
  implicitWidth: 400
  implicitHeight: root.maxHeight
  focusable: false
  exclusiveZone: 0
  mask: inputRegion

  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors {
    top: true
    right: true
  }

  margins {
    top: root.topMargin
    right: BarMetrics.margin
  }

  Region {
    id: inputRegion
    x: root.visibleContentX
    width: root.service && root.service.surfaceVisible
      ? Math.max(0, root.width - root.visibleContentX)
      : 0
    height: root.service && root.service.surfaceVisible ? animatedStack.height : 0
  }

  Item {
    id: animatedStack
    width: parent.width
    height: root.drawerHeight
    x: root.service && root.service.stackVisible ? 0 : width + 12

    Behavior on x {
      NumberAnimation {
        duration: BarMetrics.animationDuration
        easing.type: Easing.OutCubic
      }
    }

    HoverHandler {
      id: stackHover
    }

    Rectangle {
      id: drawerBackground
      anchors.fill: parent
      visible: root.service && root.service.hasVisualRecords
      color: Theme.overlay
      radius: 14
      border.width: 1
      border.color: Theme.highlightMed
    }

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
        Math.max(0, root.maxHeight - root.drawerPadding * 2
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
        ParallelAnimation {
          NumberAnimation {
            property: "x"
            from: cardList.width
            to: 0
            duration: BarMetrics.animationDuration
            easing.type: Easing.OutCubic
          }
          NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: BarMetrics.animationDuration
            easing.type: Easing.OutCubic
          }
        }
      }

      displaced: Transition {
        NumberAnimation {
          properties: "x,y"
          duration: 150
          easing.type: Easing.OutCubic
        }
      }

      remove: Transition {
        ParallelAnimation {
          NumberAnimation {
            property: "x"
            to: cardList.width
            duration: BarMetrics.animationDuration
            easing.type: Easing.InCubic
          }
          NumberAnimation {
            property: "opacity"
            to: 0
            duration: BarMetrics.animationDuration
            easing.type: Easing.InCubic
          }
          NumberAnimation {
            property: "height"
            to: 0
            duration: BarMetrics.animationDuration
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
