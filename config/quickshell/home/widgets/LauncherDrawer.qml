pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
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
  property bool screenActive: false

  readonly property bool targetOpen: Boolean(root.service
    && root.service.launcherOpen
    && root.screenActive
    && root.screen
    && root.service.targetOutput === root.screen.name)
  property real openProgress: root.targetOpen ? 1 : 0

  readonly property real edgeMargin: 12
  readonly property real minimumWidth: 180
  readonly property real maximumWidth: 420
  readonly property real cardRadius: 12
  readonly property real availableWidth: root.parent ? root.parent.width : root.maximumWidth
  readonly property real cardWidth: Math.max(root.minimumWidth,
    Math.min(root.maximumWidth, root.availableWidth - root.edgeMargin * 2))
  readonly property real cardHeight: 20 + searchField.height + resultList.height
    + (resultList.height > 0 ? 6 : 0)
  readonly property real fullHeight: root.cardHeight
  readonly property real visibleHeight: root.fullHeight * root.openProgress
  readonly property real inputHeight: root.visible ? root.visibleHeight : 0
  readonly property real triggerCenterX: root.anchorCenterX > 0
    ? root.anchorCenterX : root.availableWidth / 2
  readonly property bool alignLeft: root.triggerCenterX
    <= (root.islandLeft + root.islandRight) / 2
  readonly property real alignedX: root.alignLeft
    ? root.islandLeft : root.islandRight - root.width
  readonly property real visibleLeft: Math.max(root.x, root.surfaceLeft)
  readonly property real visibleRight: Math.min(root.x + root.width,
    root.surfaceRight)
  readonly property real visibleWidth: Math.max(0,
    root.visibleRight - root.visibleLeft)

  implicitWidth: root.cardWidth
  implicitHeight: root.fullHeight
  width: root.cardWidth
  height: root.fullHeight
  x: Math.max(root.edgeMargin,
    Math.min(root.availableWidth - root.width - root.edgeMargin,
      root.alignedX))
  visible: root.targetOpen || root.openProgress > 0.001

  Behavior on openProgress {
    NumberAnimation {
      duration: root.targetOpen ? 180 : 120
      easing.type: root.targetOpen ? Easing.OutCubic : Easing.InCubic
    }
  }

  function focusSearch(): void {
    if (root.targetOpen && root.visible)
      searchField.forceActiveFocus();
  }

  function syncSelection(): void {
    if (!root.service)
      return;

    const index = root.service.selectedIndex;
    resultList.currentIndex = index >= 0 && index < resultList.count ? index : -1;
    if (resultList.currentIndex >= 0)
      resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain);
  }

  Item {
    id: revealClip

    x: root.visibleLeft - root.x
    width: root.visibleWidth
    height: root.visibleHeight
    clip: true

    Rectangle {
      id: card

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
      height: root.cardHeight

      ListView {
        id: resultList

        readonly property int rowHeight: 44

        x: 10
        y: 10
        width: parent.width - 20
        height: Math.min(contentHeight, rowHeight * 7)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
          values: root.service ? root.service.results : []
          onValuesChanged: root.syncSelection()
        }

        Behavior on height {
          NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
          }
        }

        delegate: Item {
          id: appRow

          required property DesktopEntry modelData
          required property int index

          width: resultList.width
          height: resultList.rowHeight

          Rectangle {
            anchors.fill: parent
            radius: 10
            color: root.service && root.service.selectedIndex === appRow.index
              ? Theme.highlightHigh
              : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: 180
              }
            }
          }

          IconImage {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 30
            source: Quickshell.iconPath(appRow.modelData.icon, "image-missing")
          }

          Text {
            anchors.left: parent.left
            anchors.leftMargin: 48
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: appRow.modelData.name
            color: Theme.text
            font.pixelSize: 14
            elide: Text.ElideRight
          }

          MouseArea {
            anchors.fill: parent
            enabled: root.targetOpen
            hoverEnabled: enabled
            cursorShape: Qt.PointingHandCursor
            onEntered: root.service.selectedIndex = appRow.index
            onClicked: root.service.launch(appRow.modelData)
          }
        }
      }

      TextField {
        id: searchField

        x: 10
        y: resultList.y + resultList.height + (resultList.height > 0 ? 6 : 0)
        width: parent.width - 20
        height: 40
        enabled: root.targetOpen
        focus: root.targetOpen
        text: root.service ? root.service.query : ""
        placeholderText: "Search…"
        color: Theme.text
        placeholderTextColor: Theme.subtle
        selectionColor: Theme.rose
        selectedTextColor: Theme.surface
        leftPadding: 12
        rightPadding: 12
        font.pixelSize: 14

        background: Rectangle {
          radius: 10
          color: Theme.surface
          border.width: searchField.activeFocus ? 2 : 0
          border.color: Theme.rose

          Behavior on border.width {
            NumberAnimation {
              duration: 180
              easing.type: Easing.OutCubic
            }
          }
        }

        onTextEdited: {
          if (root.service)
            root.service.query = text;
        }

        Keys.onPressed: event => {
          if (event.key === Qt.Key_Escape) {
            root.service.closeLauncher();
            event.accepted = true;
          } else if (event.key === Qt.Key_Up) {
            if (resultList.count > 0) {
              root.service.selectedIndex = Math.max(0,
                root.service.selectedIndex - 1);
              resultList.positionViewAtIndex(root.service.selectedIndex,
                ListView.Contain);
            }
            event.accepted = true;
          } else if (event.key === Qt.Key_Down) {
            if (resultList.count > 0) {
              root.service.selectedIndex = Math.min(resultList.count - 1,
                root.service.selectedIndex + 1);
              resultList.positionViewAtIndex(root.service.selectedIndex,
                ListView.Contain);
            }
            event.accepted = true;
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.service.selectedIndex >= 0)
              root.service.launch(root.service.results[root.service.selectedIndex]);
            event.accepted = true;
          }
        }
      }
    }

  }

  Connections {
    target: root.service

    function onSelectedIndexChanged(): void {
      root.syncSelection();
    }

    function onLauncherOpenChanged(): void {
      if (root.targetOpen)
        Qt.callLater(() => root.focusSearch());
      else
        searchField.focus = false;
    }

    function onQueryChanged(): void {
      if (searchField.text !== root.service.query)
        searchField.text = root.service.query;
      root.syncSelection();
    }
  }

  onTargetOpenChanged: {
    if (root.targetOpen)
      Qt.callLater(() => root.focusSearch());
    else
      searchField.focus = false;
  }

  Component.onCompleted: root.syncSelection()
}
