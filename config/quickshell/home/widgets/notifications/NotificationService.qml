import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

Scope {
  id: root

  property var records: []
  property int closingCount: 0
  property var routedScreen: null
  readonly property var trackedNotifications: notificationServer.trackedNotifications
  readonly property var routedMonitor: root.routedScreen
    ? Hyprland.monitorFor(root.routedScreen)
    : null
  readonly property var routedWorkspace: root.routedMonitor
    ? root.workspaceForMonitor(root.routedMonitor)
    : null
  property bool stackVisible: false
  property bool surfaceVisible: false
  property bool stackHovered: false
  property bool presentationBlocked: false
  property bool reopenAfterPresentationBlock: false
  property bool manualFullscreenOverride: false
  property bool fullscreenSuppressed: false
  readonly property bool hasNotifications: root.records.length > 0
  readonly property bool hasVisualRecords: root.hasNotifications
    || root.closingCount > 0

  signal recordAdded

  function sameScreen(left, right) {
    return left === right
      || Boolean(left && right && left.name === right.name);
  }

  function isValidScreen(screen) {
    return Boolean(screen) && Quickshell.screens.some(candidate =>
      root.sameScreen(candidate, screen));
  }

  function firstScreen() {
    return Quickshell.screens[0] || null;
  }

  function focusedScreen() {
    const focusedMonitor = Hyprland.focusedMonitor;
    const match = focusedMonitor && Quickshell.screens.find(screen => {
      const monitor = Hyprland.monitorFor(screen);
      return monitor && monitor.name === focusedMonitor.name;
    });
    return match || root.firstScreen();
  }

  function routeTo(screen) {
    if (!root.isValidScreen(screen))
      return false;

    if (!root.sameScreen(root.routedScreen, screen))
      root.routedScreen = screen;
    return true;
  }

  function routeToFocused() {
    return root.routeTo(root.focusedScreen());
  }

  function workspaceForMonitor(monitor) {
    if (!monitor)
      return null;

    const monitorIpc = monitor.lastIpcObject || ({});
    const specialWorkspace = monitorIpc.specialWorkspace;
    const specialName = specialWorkspace && specialWorkspace.name
      ? specialWorkspace.name : "";
    if (!specialName)
      return monitor.activeWorkspace;

    const workspaces = Hyprland.workspaces ? Hyprland.workspaces.values : [];
    return workspaces.find(workspace => workspace.name === specialName) || null;
  }

  function workspaceHasFullscreen(workspace, monitor) {
    if (!workspace)
      return false;

    const toplevels = workspace.toplevels ? workspace.toplevels.values : [];
    return toplevels.some(toplevel => {
      const ipc = toplevel.lastIpcObject || ({});
      const onMonitor = !toplevel.monitor || !monitor
        || toplevel.monitor.name === monitor.name;
      return ipc.mapped === true && onMonitor
        && Number(ipc.fullscreen || 0) > 0;
    }) || Boolean(workspace.hasFullscreen);
  }

  function isFullscreen(screen) {
    if (!root.isValidScreen(screen))
      return false;

    const monitor = Hyprland.monitorFor(screen);
    return root.workspaceHasFullscreen(root.workspaceForMonitor(monitor), monitor);
  }

  function effectiveSuppression() {
    return Boolean(root.routedScreen)
      && root.isFullscreen(root.routedScreen)
      && !(root.manualFullscreenOverride && root.stackVisible);
  }

  function showSurface() {
    if (!root.routedScreen)
      return;

    hideSurfaceTimer.stop();
    root.surfaceVisible = true;
    root.stackVisible = true;
  }

  function hideStack() {
    root.manualFullscreenOverride = false;
    root.setStackHovered(false);
    root.stackVisible = false;
    if (root.surfaceVisible)
      hideSurfaceTimer.restart();
    root.fullscreenSuppressed = Boolean(root.routedScreen)
      && root.isFullscreen(root.routedScreen);
  }

  function revealQueued() {
    const paused = root.stackVisible && root.stackHovered;
    root.records.forEach(record => {
      if (record.queued)
        record.display(paused);
    });
  }

  function setStackHovered(value) {
    const hovered = Boolean(value) && root.surfaceVisible && root.stackVisible;
    if (root.stackHovered === hovered)
      return;

    root.stackHovered = hovered;
    root.records.forEach(record => {
      if (hovered)
        record.pauseTimer();
      else
        record.resumeTimer();
    });
  }

  function presentRecord(record, replacement) {
    if (!record || !record.active)
      return;

    if (!root.routeToFocused() && !replacement) {
      record.queue();
      root.fullscreenSuppressed = false;
      return;
    }

    if (root.presentationBlocked) {
      if (replacement)
        record.replace(false, true);
      else
        record.queue();
      root.hideStack();
      return;
    }

    root.fullscreenSuppressed = root.effectiveSuppression();
    if (root.fullscreenSuppressed) {
      if (replacement)
        record.replace(false, true);
      else
        record.queue();
      root.hideStack();
      return;
    }

    root.showSurface();
    if (replacement)
      record.replace(root.stackHovered, false);
    else
      record.display(root.stackHovered);
    root.revealQueued();
  }

  function restoreTrackedNotifications() {
    const model = root.trackedNotifications;
    if (!model)
      return;

    Array.from(model.values || []).forEach(notification => {
      root.acceptNotification(notification);
    });
  }

  function acceptNotification(notification) {
    if (!notification || !notification.tracked)
      return;

    const id = Number(notification.id);
    if (root.records.some(record => record.data.id === id))
      return;

    const record = recordComponent.createObject(root);
    if (!record)
      return;

    record.initialize(notification);
    record.replacement.connect(() => root.presentRecord(record, true));
    record.nativeClosed.connect(() => root.handleNativeClosed(record));
    record.visualRemovalFinished.connect(() => root.finishClosing(record));
    root.records = root.records.concat([record]);
    root.recordAdded();
    root.presentRecord(record, false);
  }

  function handleNativeClosed(record) {
    if (!record || !record.active)
      return;

    record.beginClosing();
    root.closingCount++;
    root.records = root.records.filter(candidate => candidate !== record);
  }

  function finishClosing(record) {
    if (!record)
      return;

    root.closingCount--;
    record.destroy();
    if (!root.hasVisualRecords) {
      root.reopenAfterPresentationBlock = false;
      root.hideStack();
    }
  }

  function clearAll() {
    root.records.forEach(record => record.dismissNative());
  }

  function toggleFor(screen) {
    if (!root.hasNotifications)
      return;

    const clickedScreen = root.isValidScreen(screen) ? screen : root.firstScreen();
    if (!clickedScreen)
      return;

    root.routeTo(clickedScreen);
    if (root.stackVisible) {
      root.hideStack();
      return;
    }

    root.manualFullscreenOverride = root.isFullscreen(clickedScreen);
    root.fullscreenSuppressed = false;
    root.showSurface();
    root.revealQueued();
  }

  function refreshFullscreenState() {
    if (root.presentationBlocked) {
      if (root.stackVisible)
        root.hideStack();
      return;
    }

    const hadRoute = Boolean(root.routedScreen);
    if (!hadRoute && root.hasNotifications && !root.routeToFocused())
      return;

    const suppressed = root.effectiveSuppression();
    const wasSuppressed = root.fullscreenSuppressed;
    root.fullscreenSuppressed = suppressed;

    if (suppressed && !wasSuppressed) {
      root.hideStack();
      return;
    }

    if (!hadRoute && !suppressed && root.hasNotifications) {
      root.showSurface();
      root.revealQueued();
      return;
    }

    if (wasSuppressed && !suppressed) {
      root.routeToFocused();
      root.fullscreenSuppressed = root.effectiveSuppression();
      if (!root.fullscreenSuppressed && root.hasNotifications) {
        root.showSurface();
        root.revealQueued();
        root.records.forEach(record => record.resumeTimer());
        root.reopenAfterPresentationBlock = false;
      }
    }
  }

  function scheduleFullscreenRefresh() {
    fullscreenRefreshTimer.restart();
  }

  onPresentationBlockedChanged: {
    if (root.presentationBlocked) {
      root.reopenAfterPresentationBlock = root.stackVisible;
      root.hideStack();
      if (root.reopenAfterPresentationBlock) {
        root.records.forEach(record => {
          if (!record.queued)
            record.pauseTimer();
        });
      }
      return;
    }

    const hasQueuedRecords = root.records.some(record => record.queued);
    if (!root.hasNotifications
        || (!root.reopenAfterPresentationBlock && !hasQueuedRecords))
      return;
    if (!root.isValidScreen(root.routedScreen) && !root.routeToFocused())
      return;

    root.fullscreenSuppressed = root.effectiveSuppression();
    if (!root.fullscreenSuppressed) {
      root.showSurface();
      root.revealQueued();
      root.records.forEach(record => record.resumeTimer());
      root.reopenAfterPresentationBlock = false;
    }
  }

  Component.onCompleted: {
    Hyprland.refreshMonitors();
    Hyprland.refreshWorkspaces();
    Hyprland.refreshToplevels();
    root.restoreTrackedNotifications();
    root.scheduleFullscreenRefresh();
  }

  Timer {
    id: hideSurfaceTimer
    interval: 300
    onTriggered: {
      if (!root.stackVisible)
        root.surfaceVisible = false;
    }
  }

  Timer {
    id: fullscreenRefreshTimer
    interval: 100
    onTriggered: root.refreshFullscreenState()
  }

  Component {
    id: recordComponent
    NotificationRecord {}
  }

  NotificationServer {
    id: notificationServer
    keepOnReload: true
    bodySupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: true
    bodyImagesSupported: false
    actionsSupported: true
    actionIconsSupported: true
    imageSupported: true
    inlineReplySupported: false
    persistenceSupported: false

    onNotification: function(notification) {
      // Tracking must happen synchronously, before any object creation or queued work.
      // The native server owns these objects, so keepOnReload can hand them to the
      // next QML generation without writing notification data to disk.
      notification.tracked = true;
      root.acceptNotification(notification);
    }

    onTrackedNotificationsChanged: root.restoreTrackedNotifications()
  }

  Connections {
    target: root.routedMonitor
    function onLastIpcObjectChanged() { root.scheduleFullscreenRefresh(); }
    function onActiveWorkspaceChanged() { root.scheduleFullscreenRefresh(); }
  }

  Connections {
    target: root.routedWorkspace
    function onHasFullscreenChanged() { root.scheduleFullscreenRefresh(); }
    function onLastIpcObjectChanged() { root.scheduleFullscreenRefresh(); }
  }

  Connections {
    target: Hyprland.toplevels
    function onValuesChanged() { root.scheduleFullscreenRefresh(); }
    function onObjectInsertedPost() { root.scheduleFullscreenRefresh(); }
    function onObjectRemovedPost() { root.scheduleFullscreenRefresh(); }
  }

  Connections {
    target: Hyprland

    function onFocusedMonitorChanged() { root.scheduleFullscreenRefresh(); }
    function onFocusedWorkspaceChanged() { root.scheduleFullscreenRefresh(); }
    function onRawEvent(event) {
      const name = event.name;
      if (name === "fullscreen"
          || name === "focusedmon"
          || name.includes("window")
          || name.includes("workspace")
          || name.includes("special")
          || name.includes("monitor")) {
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshMonitors();
        root.scheduleFullscreenRefresh();
      }
    }
  }
}
