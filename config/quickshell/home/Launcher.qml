pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme

Scope {
  id: root

  property bool launcherOpen: false
  property string query: ""
  property var apps: []
  readonly property var results: resultsFor(query)

  function reloadApps(): void {
    apps = [...DesktopEntries.applications.values]
      .filter(app => !app.noDisplay)
      .sort((a, b) => a.name.localeCompare(b.name));
  }

  function subsequenceScore(needle: string, haystack: string): real {
    let cursor = 0;
    let score = 0;

    for (let i = 0; i < needle.length; i++) {
      const position = haystack.indexOf(needle[i], cursor);
      if (position < 0)
        return -Infinity;

      score += position === cursor ? 2 : 1;
      if (position === 0 || /[\s._-]/.test(haystack[position - 1]))
        score += 4;
      cursor = position + 1;
    }

    return score - haystack.length * 0.01;
  }

  function resultsFor(searchText: string): var {
    const needle = searchText.trim().toLowerCase();
    if (!needle)
      return apps;

    return apps.map(app => {
      const name = String(app.name || "").toLowerCase();
      const genericName = String(app.genericName || "").toLowerCase();
      return {
        entry: app,
        score: Math.max(
          subsequenceScore(needle, name),
          subsequenceScore(needle, genericName)
        )
      };
    }).filter(result => result.score > -Infinity)
      .sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name))
      .map(result => result.entry);
  }

  function openLauncher(): void {
    resetTimer.stop();
    launcherOpen = true;
  }

  function closeLauncher(): void {
    if (!launcherOpen)
      return;

    launcherOpen = false;
    resetTimer.restart();
  }

  function toggleLauncher(): void {
    if (launcherOpen)
      closeLauncher();
    else
      openLauncher();
  }

  function launch(entry: var): void {
    if (!entry)
      return;

    entry.execute();
    closeLauncher();
  }

  Component.onCompleted: reloadApps()

  Connections {
    target: DesktopEntries

    function onApplicationsChanged(): void {
      root.reloadApps();
    }
  }

  Timer {
    id: resetTimer

    // Run just after the close animation so its height cannot change mid-slide.
    interval: 320
    repeat: false
    onTriggered: root.query = ""
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "launcher"
    description: "Toggle application launcher"
    onPressed: root.toggleLauncher()
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel

      required property var modelData
      readonly property bool activeScreen: {
        const monitor = Hyprland.monitorFor(screen);
        return monitor && monitor.name === Hyprland.focusedMonitor?.name;
      }

      screen: modelData
      visible: activeScreen && (root.launcherOpen || animatedPanel.visible)
      color: "transparent"
      mask: inputRegion

      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.keyboardFocus: root.launcherOpen && activeScreen
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      Region {
        id: inputRegion

        x: animatedPanel.x
        y: animatedPanel.y
        width: animatedPanel.visible ? animatedPanel.width : 0
        height: animatedPanel.height
      }

      HyprlandFocusGrab {
        active: root.launcherOpen && panel.activeScreen
        windows: [panel]
        onCleared: root.closeLauncher()
      }

      Item {
        id: animatedPanel

        property real offsetScale: root.launcherOpen && panel.activeScreen ? 0 : 1

        width: 480
        height: card.implicitHeight
        visible: panel.activeScreen && offsetScale < 1
        opacity: 1 - offsetScale

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: (-height - 8) * offsetScale

        Behavior on offsetScale {
          NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
          }
        }

        Rectangle {
          id: card

          implicitHeight: 20 + searchField.height + resultList.height
            + (resultList.height > 0 ? 6 : 0)
          anchors.fill: parent
          radius: 14
          bottomLeftRadius: 0
          bottomRightRadius: 0
          color: Theme.overlay

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
              id: resultModel

              values: root.results
              onValuesChanged: {
                resultList.currentIndex = resultList.count > 0 ? 0 : -1;
                resultList.positionViewAtBeginning();
              }
            }

            Behavior on height {
              NumberAnimation {
                duration: 300
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
                color: resultList.currentIndex === appRow.index
                  ? Theme.highlightHigh
                  : "transparent"

                Behavior on color {
                  ColorAnimation {
                    duration: 300
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
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: resultList.currentIndex = appRow.index
                onClicked: root.launch(appRow.modelData)
              }
            }
          }

          TextField {
            id: searchField

            x: 10
            y: resultList.y + resultList.height + (resultList.height > 0 ? 6 : 0)
            width: parent.width - 20
            height: 40
            text: root.query
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
                  duration: 300
                  easing.type: Easing.OutCubic
                }
              }
            }

            onTextEdited: root.query = text

            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) {
                root.closeLauncher();
                event.accepted = true;
              } else if (event.key === Qt.Key_Up) {
                if (resultList.count > 0) {
                  resultList.currentIndex = Math.max(0, resultList.currentIndex - 1);
                  resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain);
                }
                event.accepted = true;
              } else if (event.key === Qt.Key_Down) {
                if (resultList.count > 0) {
                  resultList.currentIndex = Math.min(resultList.count - 1, resultList.currentIndex + 1);
                  resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain);
                }
                event.accepted = true;
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (resultList.currentIndex >= 0)
                  root.launch(root.results[resultList.currentIndex]);
                event.accepted = true;
              }
            }
          }
        }
      }

      Connections {
        target: root

        function onLauncherOpenChanged(): void {
          if (root.launcherOpen && panel.activeScreen)
            Qt.callLater(() => searchField.forceActiveFocus());
        }

        function onQueryChanged(): void {
          resultList.currentIndex = resultList.count > 0 ? 0 : -1;
          resultList.positionViewAtBeginning();
        }
      }

      onActiveScreenChanged: {
        if (activeScreen && root.launcherOpen)
          Qt.callLater(() => searchField.forceActiveFocus());
      }
    }
  }
}
