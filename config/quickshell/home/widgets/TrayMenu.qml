pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.theme

Scope {
  id: root

  property var selectedTrayItem: null
  property Item anchorItem: null
  property var targetScreen: null
  property bool closing: false
  property bool changingTarget: false
  property bool resettingState: false
  property int geometryRevision: 0
  readonly property var rootMenuHandle: root.selectedTrayItem
    ? root.selectedTrayItem.menu : null
  readonly property bool canInteract: popup.visible && !root.closing
    && !levelStack.busy
  readonly property var currentLevel: levelStack.currentItem
  readonly property real naturalWidth: root.currentLevel
    ? root.currentLevel.naturalWidth : 220
  readonly property real naturalHeight: root.currentLevel
    ? root.currentLevel.naturalHeight : 42
  readonly property real availableWidth: Math.max(1,
    (root.targetScreen ? root.targetScreen.width : 1) - 16)
  readonly property real cardWidth: Math.min(root.availableWidth,
    Math.max(220, Math.min(360, root.naturalWidth)))
  readonly property real anchorTop: {
    root.geometryRevision;
    if (!root.anchorItem)
      return 0;

    const top = root.anchorItem.mapToGlobal(0, 0);
    const bottom = root.anchorItem.mapToGlobal(0, root.anchorItem.height);
    return Math.min(top.y, bottom.y);
  }
  readonly property real anchorBottom: {
    root.geometryRevision;
    if (!root.anchorItem)
      return 0;

    const top = root.anchorItem.mapToGlobal(0, 0);
    const bottom = root.anchorItem.mapToGlobal(0, root.anchorItem.height);
    return Math.max(top.y, bottom.y);
  }
  readonly property real maximumCardHeight: {
    if (!root.targetScreen || !root.anchorItem)
      return root.naturalHeight;

    const screenTop = root.targetScreen.y;
    const screenBottom = screenTop + root.targetScreen.height;
    const below = Math.max(0, screenBottom - 8
      - (root.anchorBottom + 8));
    const above = Math.max(0, root.anchorTop - 8
      - (screenTop + 8));
    return Math.max(below, above);
  }
  readonly property real cardHeight: Math.max(1,
    Math.min(root.naturalHeight, root.maximumCardHeight))

  function isOpenFor(item, anchor): bool {
    return popup.visible && root.selectedTrayItem === item
      && (!anchor || root.anchorItem === anchor);
  }

  function open(item, anchor, screen): void {
    if (!item || !anchor || !screen || !item.hasMenu)
      return;

    root.changingTarget = true;
    root.cancelAnimations();
    root.closing = false;
    root.selectedTrayItem = item;
    root.anchorItem = anchor;
    root.targetScreen = screen;
    root.geometryRevision++;
    root.resetToRoot();
    root.changingTarget = false;

    popup.anchor.updateAnchor();
    card.opacity = 0;
    card.scale = 0.96;
    popup.visible = true;
    openAnimation.restart();
    root.scheduleFocus();
  }

  function toggle(item, anchor, screen): void {
    if (!item || !anchor || !screen || !item.hasMenu)
      return;

    if (popup.visible && root.selectedTrayItem === item
        && root.anchorItem === anchor) {
      root.close();
      return;
    }

    root.open(item, anchor, screen);
  }

  function close(): void {
    if (!popup.visible || root.closing)
      return;

    root.closing = true;
    openAnimation.stop();
    closeAnimation.restart();
  }

  function closeImmediately(): void {
    root.cancelAnimations();
    root.closing = true;
    if (levelStack.depth > 0)
      levelStack.clear(StackView.Immediate);
    popup.visible = false;
  }

  function cancelAnimations(): void {
    openAnimation.stop();
    closeAnimation.stop();
  }

  function resetToRoot(): void {
    if (levelStack.depth > 0)
      levelStack.clear(StackView.Immediate);
    levelStack.push(menuLevelComponent, {
      "rootLevel": true,
      "handle": null,
      "parentEntry": null
    }, StackView.Immediate);
    root.scheduleAnchorUpdate();
  }

  function resetAllState(): void {
    root.resettingState = true;
    root.cancelAnimations();
    validateStackTimer.stop();
    anchorUpdateTimer.stop();
    if (levelStack.depth > 0)
      levelStack.clear(StackView.Immediate);
    root.closing = false;
    card.opacity = 0;
    card.scale = 0.96;
    root.selectedTrayItem = null;
    root.anchorItem = null;
    root.targetScreen = null;
    root.geometryRevision++;
    root.resettingState = false;
  }

  function pushSubmenu(entry): void {
    if (!root.canInteract || !entry || !entry.enabled
        || entry.isSeparator || !entry.hasChildren)
      return;

    levelStack.push(menuLevelComponent, {
      "rootLevel": false,
      "handle": entry,
      "parentEntry": entry
    });
  }

  function popSubmenu(): void {
    if (!popup.visible || root.closing || levelStack.busy
        || levelStack.depth <= 1)
      return;

    levelStack.pop();
  }

  function activateEntry(entry, allowLeaf): void {
    if (!root.canInteract || !entry || !entry.enabled || entry.isSeparator)
      return;

    if (entry.hasChildren) {
      root.pushSubmenu(entry);
      return;
    }

    if (!allowLeaf)
      return;

    entry.triggered();
    root.close();
  }

  function scheduleFocus(): void {
    Qt.callLater(() => {
      if (!popup.visible || root.closing || levelStack.busy
          || !levelStack.currentItem)
        return;
      levelStack.currentItem.forceActiveFocus();
      levelStack.currentItem.ensureSelectionVisible();
    });
  }

  function scheduleAnchorUpdate(): void {
    anchorUpdateTimer.restart();
  }

  function scheduleStackValidation(): void {
    validateStackTimer.restart();
  }

  function validateStack(): void {
    if (!popup.visible || root.closing || root.changingTarget)
      return;

    if (!root.selectedTrayItem || !root.anchorItem
        || !root.selectedTrayItem.hasMenu) {
      root.closeImmediately();
      return;
    }

    if (levelStack.busy)
      return;

    for (let index = 1; index < levelStack.depth; index++) {
      const parentLevel = levelStack.get(index - 1);
      const childLevel = levelStack.get(index);
      const entry = childLevel ? childLevel.parentEntry : null;
      if (!parentLevel || !entry || !entry.hasChildren
          || parentLevel.indexOfEntry(entry) < 0) {
        levelStack.pop(parentLevel, StackView.Immediate);
        root.scheduleFocus();
        break;
      }
    }
  }

  onRootMenuHandleChanged: {
    if (!root.resettingState && !root.changingTarget && popup.visible
        && root.selectedTrayItem && root.selectedTrayItem.hasMenu)
      root.resetToRoot();
  }
  onCardWidthChanged: root.scheduleAnchorUpdate()
  onCardHeightChanged: root.scheduleAnchorUpdate()

  Timer {
    id: anchorUpdateTimer

    interval: 0
    repeat: false
    onTriggered: {
      if (popup.visible && root.anchorItem) {
        root.geometryRevision++;
        popup.anchor.updateAnchor();
      }
    }
  }

  Timer {
    id: validateStackTimer

    interval: 0
    repeat: false
    onTriggered: root.validateStack()
  }

  Connections {
    target: SystemTray.items

    function onObjectRemovedPre(item, index): void {
      if (item === root.selectedTrayItem)
        root.closeImmediately();
    }
  }

  Connections {
    target: root.selectedTrayItem
    ignoreUnknownSignals: true

    function onHasMenuChanged(): void {
      if (!root.selectedTrayItem)
        return;
      if (!root.selectedTrayItem.hasMenu)
        root.close();
      else if (popup.visible && !root.changingTarget)
        root.resetToRoot();
    }

    function onDestroyed(): void {
      root.closeImmediately();
    }
  }

  Connections {
    target: root.anchorItem
    ignoreUnknownSignals: true

    function onXChanged(): void { root.scheduleAnchorUpdate(); }
    function onYChanged(): void { root.scheduleAnchorUpdate(); }
    function onWidthChanged(): void { root.scheduleAnchorUpdate(); }
    function onHeightChanged(): void { root.scheduleAnchorUpdate(); }
    function onWindowChanged(): void { root.scheduleAnchorUpdate(); }
    function onDestroyed(): void { root.closeImmediately(); }
  }

  Connections {
    target: root.targetScreen
    ignoreUnknownSignals: true

    function onGeometryChanged(): void { root.scheduleAnchorUpdate(); }
    function onDestroyed(): void { root.closeImmediately(); }
  }

  ParallelAnimation {
    id: openAnimation

    NumberAnimation {
      target: card
      property: "opacity"
      to: 1
      duration: 140
      easing.type: Easing.OutCubic
    }

    NumberAnimation {
      target: card
      property: "scale"
      to: 1
      duration: 140
      easing.type: Easing.OutCubic
    }
  }

  ParallelAnimation {
    id: closeAnimation

    NumberAnimation {
      target: card
      property: "opacity"
      to: 0
      duration: 100
      easing.type: Easing.OutCubic
    }

    NumberAnimation {
      target: card
      property: "scale"
      to: 0.96
      duration: 100
      easing.type: Easing.OutCubic
    }

    onFinished: popup.visible = false
  }

  PopupWindow {
    id: popup

    visible: false
    color: "transparent"
    implicitWidth: root.cardWidth
    implicitHeight: root.cardHeight
    grabFocus: true

    anchor {
      item: root.anchorItem
      edges: Edges.Bottom | Edges.Left
      gravity: Edges.Bottom | Edges.Right
      margins.top: -8
      margins.bottom: -8
      adjustment: PopupAdjustment.All
    }

    onVisibleChanged: {
      if (visible)
        root.scheduleFocus();
      else
        root.resetAllState();
    }

    Rectangle {
      id: card

      width: popup.width
      height: popup.height
      transformOrigin: Item.TopLeft
      opacity: 0
      scale: 0.96
      color: Theme.barSurface
      radius: 12
      border.width: 1
      border.color: Theme.highlightMed
      clip: true

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
      }

      StackView {
        id: levelStack

        anchors.fill: parent
        anchors.margins: 6
        clip: true
        focus: true

        pushEnter: Transition {
          ParallelAnimation {
            NumberAnimation {
              property: "x"
              from: 16
              to: 0
              duration: 140
              easing.type: Easing.OutCubic
            }
            NumberAnimation {
              property: "opacity"
              from: 0
              to: 1
              duration: 140
              easing.type: Easing.OutCubic
            }
          }
        }
        pushExit: Transition {
          ParallelAnimation {
            NumberAnimation {
              property: "x"
              from: 0
              to: -16
              duration: 140
              easing.type: Easing.OutCubic
            }
            NumberAnimation {
              property: "opacity"
              from: 1
              to: 0
              duration: 140
              easing.type: Easing.OutCubic
            }
          }
        }
        popEnter: Transition {
          ParallelAnimation {
            NumberAnimation {
              property: "x"
              from: -16
              to: 0
              duration: 140
              easing.type: Easing.OutCubic
            }
            NumberAnimation {
              property: "opacity"
              from: 0
              to: 1
              duration: 140
              easing.type: Easing.OutCubic
            }
          }
        }
        popExit: Transition {
          ParallelAnimation {
            NumberAnimation {
              property: "x"
              from: 0
              to: 16
              duration: 140
              easing.type: Easing.OutCubic
            }
            NumberAnimation {
              property: "opacity"
              from: 1
              to: 0
              duration: 140
              easing.type: Easing.OutCubic
            }
          }
        }

        onCurrentItemChanged: {
          root.scheduleAnchorUpdate();
          root.scheduleFocus();
        }
        onBusyChanged: {
          if (!busy) {
            root.validateStack();
            root.scheduleFocus();
          }
        }
      }
    }
  }

  Component {
    id: menuLevelComponent

    MenuLevel {}
  }

  component MenuLevel: FocusScope {
    id: level

    required property bool rootLevel
    required property var handle
    required property var parentEntry
    property var selectedEntry: null
    property int dataRevision: 0
    readonly property var entries: {
      level.dataRevision;
      return menuOpener.children && menuOpener.children.values
        ? menuOpener.children.values : [];
    }
    readonly property bool reserveCheck: {
      for (const entry of level.entries) {
        if (entry.buttonType !== QsMenuButtonType.None
            && entry.checkState !== Qt.Unchecked)
          return true;
      }
      return false;
    }
    readonly property bool reserveIcon: {
      for (const entry of level.entries) {
        if (entry.icon)
          return true;
      }
      return false;
    }
    readonly property bool reserveChevron: {
      for (const entry of level.entries) {
        if (entry.hasChildren)
          return true;
      }
      return false;
    }
    readonly property real entriesHeight: {
      let height = 0;
      for (const entry of level.entries)
        height += entry.isSeparator ? 9 : 30;
      return Math.max(30, height);
    }
    readonly property real widestEntryWidth: {
      let widest = 0;
      const columnCount = 1 + (level.reserveCheck ? 1 : 0)
        + (level.reserveIcon ? 1 : 0)
        + (level.reserveChevron ? 1 : 0);
      const fixedWidth = 16 + (level.reserveCheck ? 14 : 0)
        + (level.reserveIcon ? 16 : 0)
        + (level.reserveChevron ? 14 : 0)
        + Math.max(0, columnCount - 1) * 6;
      for (const entry of level.entries) {
        if (!entry.isSeparator)
          widest = Math.max(widest,
            fixedWidth + labelMetrics.advanceWidth(entry.text));
      }
      return widest + 12;
    }
    readonly property real backWidth: level.rootLevel ? 0
      : 12 + 16 + 14 + 6 + labelMetrics.advanceWidth("Back")
    readonly property real placeholderWidth: level.entries.length > 0 ? 0
      : 12 + 16 + labelMetrics.advanceWidth("No actions")
    readonly property real naturalWidth: Math.max(level.widestEntryWidth,
      level.backWidth, level.placeholderWidth)
    readonly property real naturalHeight: 12
      + (level.rootLevel ? 0 : 30) + level.entriesHeight
    readonly property bool activeLevel: StackView.status === StackView.Active

    function indexOfEntry(entry): int {
      return menuOpener.children ? menuOpener.children.indexOf(entry) : -1;
    }

    function selectable(entry): bool {
      return Boolean(entry && entry.enabled && !entry.isSeparator);
    }

    function firstSelectableIndex(): int {
      for (let index = 0; index < level.entries.length; index++) {
        if (level.selectable(level.entries[index]))
          return index;
      }
      return -1;
    }

    function reconcileSelection(): void {
      let index = level.indexOfEntry(level.selectedEntry);
      if (index < 0 || !level.selectable(level.entries[index])) {
        index = level.firstSelectableIndex();
        level.selectedEntry = index >= 0 ? level.entries[index] : null;
      }
      actionList.currentIndex = index;
      level.ensureSelectionVisible();
      root.scheduleStackValidation();
      root.scheduleAnchorUpdate();
    }

    function scheduleReconcile(): void {
      reconcileTimer.restart();
    }

    function ensureSelectionVisible(): void {
      const index = level.indexOfEntry(level.selectedEntry);
      if (index >= 0)
        Qt.callLater(() => actionList.positionViewAtIndex(index,
          ListView.Contain));
    }

    function selectRelative(offset): void {
      if (level.entries.length === 0)
        return;

      let index = level.indexOfEntry(level.selectedEntry);
      if (index < 0) {
        index = level.firstSelectableIndex();
      } else {
        for (let candidate = index + offset;
             candidate >= 0 && candidate < level.entries.length;
             candidate += offset) {
          if (level.selectable(level.entries[candidate])) {
            index = candidate;
            break;
          }
        }
      }

      if (index >= 0) {
        level.selectedEntry = level.entries[index];
        actionList.currentIndex = index;
        actionList.positionViewAtIndex(index, ListView.Contain);
      }
    }

    function bumpData(): void {
      level.dataRevision++;
      level.scheduleReconcile();
    }

    Component.onCompleted: level.scheduleReconcile()
    StackView.onActivated: {
      level.scheduleReconcile();
      root.scheduleFocus();
    }

    Keys.onPressed: event => {
      if (!level.activeLevel || !popup.visible || root.closing) {
        event.accepted = true;
        return;
      }

      switch (event.key) {
      case Qt.Key_Down:
        level.selectRelative(1);
        break;
      case Qt.Key_Up:
        level.selectRelative(-1);
        break;
      case Qt.Key_Return:
      case Qt.Key_Enter:
        root.activateEntry(level.selectedEntry, true);
        break;
      case Qt.Key_Right:
        root.activateEntry(level.selectedEntry, false);
        break;
      case Qt.Key_Left:
        root.popSubmenu();
        break;
      case Qt.Key_Escape:
        root.close();
        break;
      case Qt.Key_Space:
      case Qt.Key_Home:
      case Qt.Key_End:
      case Qt.Key_Tab:
      case Qt.Key_Backtab:
        break;
      default:
        // Printable and mnemonic-like input are deliberately ignored, as are
        // other keys, so focus cannot leak into ListView's default handling.
        break;
      }
      event.accepted = true;
    }

    FontMetrics {
      id: labelMetrics

      font.family: Theme.iconFont
      font.pixelSize: 14
    }

    QsMenuOpener {
      id: menuOpener

      menu: level.rootLevel
        ? (root.selectedTrayItem ? root.selectedTrayItem.menu : null)
        : level.handle
    }

    Connections {
      target: menuOpener

      function onChildrenChanged(): void { level.bumpData(); }
    }

    Connections {
      target: menuOpener.children
      ignoreUnknownSignals: true

      function onValuesChanged(): void { level.bumpData(); }
    }

    Repeater {
      model: menuOpener.children

      Item {
        required property var modelData
        visible: false
        width: 0
        height: 0

        Connections {
          target: modelData

          function onTextChanged(): void { level.bumpData(); }
          function onIconChanged(): void { level.bumpData(); }
          function onEnabledChanged(): void { level.bumpData(); }
          function onIsSeparatorChanged(): void { level.bumpData(); }
          function onHasChildrenChanged(): void { level.bumpData(); }
          function onButtonTypeChanged(): void { level.bumpData(); }
          function onCheckStateChanged(): void { level.bumpData(); }
        }
      }
    }

    Timer {
      id: reconcileTimer

      interval: 0
      repeat: false
      onTriggered: level.reconcileSelection()
    }

    Item {
      anchors.fill: parent

      Rectangle {
        id: backRow

        visible: !level.rootLevel
        x: 0
        y: 0
        width: parent.width
        height: visible ? 30 : 0
        radius: 9
        color: backMouse.containsMouse && root.canInteract
          && level.activeLevel ? Theme.hover : "transparent"

        Behavior on color {
          ColorAnimation {
            duration: 120
          }
        }

        Row {
          x: 8
          width: parent.width - 16
          height: parent.height
          spacing: 6

          Text {
            width: 14
            height: parent.height
            text: "‹"
            color: Theme.accent
            font.family: Theme.iconFont
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            width: parent.width - 20
            height: parent.height
            text: "Back"
            textFormat: Text.PlainText
            color: Theme.text
            font.family: Theme.iconFont
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            maximumLineCount: 1
          }
        }

        MouseArea {
          id: backMouse

          anchors.fill: parent
          enabled: level.activeLevel && root.canInteract
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.popSubmenu()
        }
      }

      ListView {
        id: actionList

        x: 0
        y: backRow.height
        width: parent.width
        height: Math.max(0, parent.height - y)
        model: menuOpener.children
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: false
        highlightFollowsCurrentItem: false
        reuseItems: false

        ScrollBar.vertical: ScrollBar {
          width: 3
          policy: ScrollBar.AsNeeded

          contentItem: Rectangle {
            implicitWidth: 3
            radius: 2
            color: Theme.muted
          }

          background: Item {}
        }

        delegate: Item {
          id: actionSlot

          required property var modelData
          required property int index
          width: actionList.width
          height: modelData.isSeparator ? 9 : 30

          Rectangle {
            visible: actionSlot.modelData.isSeparator
            x: 8
            y: 4
            width: Math.max(0, parent.width - 16)
            height: 1
            color: Theme.highlightMed
          }

          Rectangle {
            id: actionRow

            visible: !actionSlot.modelData.isSeparator
            anchors.fill: parent
            radius: 9
            color: actionSlot.modelData.enabled
              && ((rowMouse.containsMouse && root.canInteract
                && level.activeLevel)
                || level.selectedEntry === actionSlot.modelData)
              ? Theme.hover : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: 120
              }
            }

            Row {
              id: rowContent

              x: 8
              width: parent.width - 16
              height: parent.height
              spacing: 6

              Item {
                visible: level.reserveCheck
                width: 14
                height: parent.height

                Text {
                  anchors.fill: parent
                  text: actionSlot.modelData.buttonType
                    === QsMenuButtonType.None
                    || actionSlot.modelData.checkState === Qt.Unchecked
                    ? ""
                    : actionSlot.modelData.checkState === Qt.PartiallyChecked
                      ? "−" : "✓"
                  color: Theme.accent
                  opacity: actionSlot.modelData.enabled ? 1 : 0.45
                  font.family: Theme.iconFont
                  font.pixelSize: 14
                  verticalAlignment: Text.AlignVCenter
                  horizontalAlignment: Text.AlignHCenter
                }
              }

              Item {
                visible: level.reserveIcon
                width: 16
                height: parent.height

                IconImage {
                  anchors.centerIn: parent
                  width: 16
                  height: 16
                  source: actionSlot.modelData.icon
                  opacity: actionSlot.modelData.enabled ? 1 : 0.45
                }
              }

              Text {
                readonly property real reservedWidth:
                  (level.reserveCheck ? 14 + 6 : 0)
                  + (level.reserveIcon ? 16 + 6 : 0)
                  + (level.reserveChevron ? 14 + 6 : 0)

                width: Math.max(0, rowContent.width - reservedWidth)
                height: parent.height
                text: actionSlot.modelData.text
                textFormat: Text.PlainText
                color: actionSlot.modelData.enabled
                  ? Theme.text : Theme.muted
                font.family: Theme.iconFont
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                maximumLineCount: 1
              }

              Item {
                visible: level.reserveChevron
                width: 14
                height: parent.height

                Text {
                  anchors.fill: parent
                  text: actionSlot.modelData.hasChildren ? "›" : ""
                  color: Theme.accent
                  opacity: actionSlot.modelData.enabled ? 1 : 0.45
                  font.family: Theme.iconFont
                  font.pixelSize: 14
                  verticalAlignment: Text.AlignVCenter
                  horizontalAlignment: Text.AlignHCenter
                }
              }
            }

            MouseArea {
              id: rowMouse

              anchors.fill: parent
              enabled: level.activeLevel && root.canInteract
                && actionSlot.modelData.enabled
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: {
                level.selectedEntry = actionSlot.modelData;
                actionList.currentIndex = actionSlot.index;
                level.ensureSelectionVisible();
              }
              onClicked: root.activateEntry(actionSlot.modelData, true)
            }
          }
        }
      }

      Rectangle {
        visible: level.entries.length === 0
        x: 0
        y: backRow.height
        width: parent.width
        height: 30
        radius: 9
        color: "transparent"

        Text {
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          text: "No actions"
          textFormat: Text.PlainText
          color: Theme.muted
          font.family: Theme.iconFont
          font.pixelSize: 14
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
          maximumLineCount: 1
        }
      }
    }
  }
}
