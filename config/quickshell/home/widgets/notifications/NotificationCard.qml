pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.components
import qs.config
import qs.theme

Rectangle {
  id: root

  required property var modelData
  readonly property var record: modelData
  readonly property var details: root.record ? root.record.data : ({})
  readonly property bool expanded: root.record ? root.record.expanded : false
  readonly property bool bodyExists: Boolean(root.details.body)
  readonly property int collapsedBodyLineCount: 4
  readonly property string bodyText: String(root.details.body || "")
    .replace(/<img\b[^>]*\/?>|<\/img>/gi, "")
  readonly property string imageSource: String(root.details.image || "")
  readonly property bool imageReady: imageProbe.status === Image.Ready
  readonly property string fallbackIcon: root.fallbackIconFor(root.details.urgency)
  readonly property string appIconSource: root.resolveIcon(root.details.appIcon, "")
  readonly property string fallbackIconSource: root.resolveIcon("", root.fallbackIcon)
  readonly property bool showAppIcon: root.expanded || !root.imageReady
  readonly property var actions: root.details.actions || []
  readonly property var defaultAction: root.actions.find(action =>
    action && action.identifier === "default") || null
  readonly property var nonDefaultActions: root.actions.filter(action =>
    action && action.identifier !== "default")
  readonly property bool hasExtraContent: Boolean(bodyMeasure.truncated)
    || Boolean(root.details.appName)
    || root.imageReady
    || root.nonDefaultActions.length > 0
  readonly property color urgencyAccent: root.accentFor(root.details.urgency)
  readonly property real controlsWidth: root.hasExtraContent ? 68 : 34

  width: ListView.view ? ListView.view.width : 400
  implicitHeight: Math.max(64, 20 + topRow.height
    + (root.expanded ? expandedContent.implicitHeight + 6 : 0))
  height: implicitHeight
  color: Theme.surface
  radius: 10
  border.width: 2
  border.color: root.urgencyAccent
  clip: true

  Behavior on height {
    NumberAnimation {
      duration: 150
      easing.type: Easing.OutCubic
    }
  }

  function accentFor(urgency) {
    return urgency === NotificationUrgency.Low ? Theme.muted
      : urgency === NotificationUrgency.Critical ? Theme.love : Theme.rose;
  }

  function fallbackIconFor(urgency) {
    return urgency === NotificationUrgency.Low ? "dialog-information"
      : urgency === NotificationUrgency.Critical ? "dialog-error" : "dialog-warning";
  }

  function resolveIcon(icon, fallback) {
    const value = String(icon || "");
    if (value.length > 0) {
      try {
        const direct = Quickshell.iconPath(value, true);
        if (direct)
          return direct;
      } catch (_) {
      }

      if (value.startsWith("image://"))
        return value;
    }

    if (!fallback)
      return "";

    try {
      return Quickshell.iconPath(fallback, true) || Quickshell.iconPath(fallback);
    } catch (_) {
      return "";
    }
  }

  function invokeAction(action) {
    if (root.record && root.record.active && action)
      root.record.invokeAction(action);
  }

  Text {
    id: bodyMeasure
    x: -10000
    width: summaryColumn.width
    visible: root.bodyExists
    opacity: 0
    font.pixelSize: 12
    text: root.bodyText
    textFormat: Text.StyledText
    wrapMode: Text.Wrap
    maximumLineCount: root.collapsedBodyLineCount
    elide: Text.ElideRight
  }

  Image {
    id: imageProbe
    visible: false
    asynchronous: true
    cache: false
    source: root.imageSource
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.defaultAction !== null && root.record && root.record.active
    cursorShape: Qt.PointingHandCursor
    onClicked: root.invokeAction(root.defaultAction)
  }

  Column {
    x: 10
    y: 10
    width: parent.width - 20
    spacing: 6
    z: 1

    Item {
      id: topRow
      width: parent.width
      height: Math.max(32, summaryText.height
        + (collapsedBody.visible ? summaryColumn.spacing + collapsedBody.height : 0))

      Rectangle {
        width: 32
        height: 32
        radius: 8
        color: Theme.overlay
        border.width: 1
        border.color: root.urgencyAccent
        clip: true

        Image {
          anchors.fill: parent
          visible: !root.expanded && root.imageReady
          asynchronous: true
          cache: false
          fillMode: Image.PreserveAspectCrop
          source: root.imageSource
        }

        IconImage {
          id: appIcon
          anchors.fill: parent
          anchors.margins: 4
          visible: root.showAppIcon && status === Image.Ready
          source: root.appIconSource
          asynchronous: true
          implicitSize: 24
        }

        IconImage {
          anchors.fill: parent
          anchors.margins: 4
          visible: root.showAppIcon && appIcon.status !== Image.Ready
          source: root.fallbackIconSource
          asynchronous: true
          implicitSize: 24
        }
      }

      Column {
        id: summaryColumn
        x: 42
        width: parent.width - 42 - root.controlsWidth
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
          id: summaryText

          width: parent.width
          color: root.urgencyAccent
          font.pixelSize: 14
          font.weight: Font.DemiBold
          text: String(root.details.summary || "")
          textFormat: Text.PlainText
          maximumLineCount: 1
          elide: Text.ElideRight
        }

        Text {
          id: collapsedBody

          width: parent.width
          visible: !root.expanded && root.bodyExists
          color: Theme.text
          font.pixelSize: 12
          text: root.bodyText
          textFormat: Text.StyledText
          wrapMode: Text.Wrap
          maximumLineCount: root.collapsedBodyLineCount
          elide: Text.ElideRight
          onLinkActivated: link => Qt.openUrlExternally(link)
        }
      }

      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 32
        z: 3

        IconButton {
          visible: root.hasExtraContent
          icon: root.expanded ? "󰅀" : "󰅂"
          onClicked: {
            if (root.record)
              root.record.expanded = !root.record.expanded;
          }
        }

        IconButton {
          icon: "󰅖"
          onClicked: {
            if (root.record)
              root.record.dismissNative();
          }
        }
      }
    }

    Column {
      id: expandedContent
      width: parent.width
      height: root.expanded ? implicitHeight : 0
      spacing: 6
      visible: root.expanded

      Text {
        visible: Boolean(root.details.appName)
        width: parent.width
        color: Theme.text
        font.pixelSize: 11
        elide: Text.ElideRight
        text: String(root.details.appName || "")
        textFormat: Text.PlainText
      }

      Text {
        visible: root.bodyExists
        width: parent.width
        color: Theme.text
        font.pixelSize: 12
        text: root.bodyText
        textFormat: Text.RichText
        wrapMode: Text.Wrap
        onLinkActivated: link => Qt.openUrlExternally(link)
      }

      Rectangle {
        visible: root.imageReady
        width: parent.width
        height: root.imageReady && fullImage.sourceSize.width > 0
          ? Math.min(180, width * fullImage.sourceSize.height / fullImage.sourceSize.width)
          : 0
        radius: 8
        color: Theme.overlay

        Image {
          id: fullImage
          anchors.fill: parent
          anchors.margins: 1
          asynchronous: true
          cache: false
          fillMode: Image.PreserveAspectFit
          source: root.imageSource
        }
      }

      Flow {
        id: actionFlow
        width: parent.width
        spacing: 5
        visible: root.nonDefaultActions.length > 0

        Repeater {
          model: root.nonDefaultActions

          PillButton {
            id: actionItem
            required property var modelData

            readonly property string iconSource: root.details.hasActionIcons
              ? root.resolveIcon(modelData ? modelData.identifier : "", "") : ""
            readonly property bool iconReady: actionIcon.status === Image.Ready
            readonly property real horizontalPadding: 9
            readonly property real iconGap: 5
            readonly property real iconWidth: 14
            readonly property real naturalWidth: actionLabel.implicitWidth
              + horizontalPadding * 2
              + (iconReady ? iconWidth + iconGap : 0)
            implicitWidth: Math.max(52, naturalWidth)
            width: Math.min(actionFlow.width, actionItem.implicitWidth)
            height: 26
            clip: true
            normalColor: Theme.surface
            hoverColor: Theme.highlightHigh
            radius: 6
            borderWidth: 1
            borderColor: root.urgencyAccent
            onClicked: root.invokeAction(actionItem.modelData)

            IconImage {
              id: actionIcon
              anchors.left: parent.left
              anchors.leftMargin: actionItem.horizontalPadding
              anchors.verticalCenter: parent.verticalCenter
              width: actionItem.iconWidth
              height: actionItem.iconWidth
              visible: actionItem.iconReady
              source: actionItem.iconSource
              asynchronous: true
              implicitSize: actionItem.iconWidth
            }

            Text {
              id: actionLabel
              anchors.left: actionItem.iconReady
                ? actionIcon.right : parent.left
              anchors.leftMargin: actionItem.iconReady
                ? actionItem.iconGap : actionItem.horizontalPadding
              anchors.right: parent.right
              anchors.rightMargin: actionItem.horizontalPadding
              anchors.verticalCenter: parent.verticalCenter
              color: Theme.text
              font.pixelSize: 11
              font.weight: Font.Medium
              elide: Text.ElideRight
              text: actionItem.modelData ? actionItem.modelData.text : ""
              textFormat: Text.PlainText
            }
          }
        }
      }
    }
  }
}
