pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
  id: root

  property bool launcherOpen: false
  property string targetOutput: ""
  property string query: ""
  property var apps: []
  property int selectedIndex: -1
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

  function focusedOutput(): string {
    return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
  }

  function resetSelection(): void {
    selectedIndex = results.length > 0 ? 0 : -1;
  }

  function openLauncher(outputName: string): void {
    const target = outputName || root.focusedOutput();
    if (!target)
      return;

    resetTimer.stop();
    root.targetOutput = target;
    root.launcherOpen = true;
    root.resetSelection();
  }

  function closeLauncher(): void {
    if (!root.launcherOpen)
      return;

    root.launcherOpen = false;
    root.targetOutput = "";
    resetTimer.restart();
  }

  function toggleLauncher(outputName: string): void {
    const target = outputName || root.focusedOutput();
    if (!target)
      return;

    if (root.launcherOpen)
      root.closeLauncher();
    else
      root.openLauncher(target);
  }

  function launch(entry: var): void {
    if (!entry)
      return;

    entry.execute();
    root.closeLauncher();
  }

  Component.onCompleted: root.reloadApps()
  onResultsChanged: root.resetSelection()

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
    onPressed: root.toggleLauncher(root.focusedOutput())
  }
}
