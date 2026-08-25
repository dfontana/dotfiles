pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import Quickshell
import Quickshell.Services.Notifications

Scope {
  id: root

  property var nativeNotification: null
  property var data: ({})
  property bool active: true
  property bool queued: true
  property bool expanded: false
  property bool timerStarted: false
  property real remainingMs: 0
  property real timerDeadline: 0

  signal replacement
  signal nativeClosed
  signal visualRemovalFinished

  function syncFromNative() {
    const notification = root.nativeNotification;
    if (!notification)
      return;

    root.data = {
      id: Number(notification.id),
      summary: String(notification.summary || ""),
      body: String(notification.body || ""),
      appName: String(notification.appName || ""),
      appIcon: String(notification.appIcon || ""),
      image: String(notification.image || ""),
      urgency: Number(notification.urgency),
      resident: Boolean(notification.resident),
      hasActionIcons: Boolean(notification.hasActionIcons),
      expireTimeout: Number(notification.expireTimeout),
      actions: Array.from(notification.actions || [])
    };
  }

  function initialize(notification) {
    root.nativeNotification = notification;
    root.syncFromNative();
    root.resetTimeout();
  }

  function resetTimeout() {
    expiryTimer.stop();
    const timeout = root.data.expireTimeout;
    root.remainingMs = Math.max(0, timeout >= 0
      ? timeout
      : root.data.urgency === NotificationUrgency.Critical ? 0 : 10000);
    root.timerStarted = false;
    root.timerDeadline = 0;
  }

  function display(paused) {
    if (!root.active)
      return;

    root.queued = false;
    root.resetTimeout();
    root.timerStarted = root.remainingMs > 0;
    if (root.timerStarted && !paused)
      root.resumeTimer();
  }

  function queue() {
    if (!root.active)
      return;

    root.queued = true;
    root.resetTimeout();
  }

  function pauseTimer() {
    if (!root.active || !root.timerStarted || !root.timerDeadline)
      return;

    root.remainingMs = Math.max(0, root.timerDeadline - Date.now());
    root.timerDeadline = 0;
    expiryTimer.stop();
  }

  function resumeTimer() {
    if (!root.active || !root.timerStarted || root.timerDeadline)
      return;

    if (root.remainingMs <= 0) {
      root.timerStarted = false;
      root.expireNative();
      return;
    }

    root.timerDeadline = Date.now() + root.remainingMs;
    expiryTimer.interval = Math.max(1, Math.ceil(root.remainingMs));
    expiryTimer.restart();
  }

  function replace(paused, suppressed) {
    if (!root.active)
      return;

    root.expanded = false;
    if (suppressed)
      root.queue();
    else
      root.display(paused);
  }

  function dismissNative() {
    if (root.active && root.nativeNotification)
      root.nativeNotification.dismiss();
  }

  function expireNative() {
    if (root.active && root.nativeNotification)
      root.nativeNotification.expire();
  }

  function invokeAction(action) {
    if (!root.active || !root.nativeNotification || !action)
      return;

    // NotificationAction.invoke() implements the notification spec's resident
    // rule. Keep the state check here as a defensive fallback for a backend
    // that reports the action without closing a non-resident notification.
    const resident = Boolean(root.nativeNotification.resident);
    action.invoke();
    if (!resident && root.active)
      root.dismissNative();
  }

  function beginClosing() {
    if (!root.active)
      return;

    root.syncFromNative();
    root.active = false;
    root.queued = false;
    root.timerStarted = false;
    root.timerDeadline = 0;
    expiryTimer.stop();
    replacementTimer.stop();
    exitTimer.restart();
  }

  function scheduleReplacement() {
    if (root.active)
      replacementTimer.restart();
  }

  Timer {
    id: expiryTimer

    onTriggered: {
      if (!root.active || !root.timerStarted || !root.timerDeadline)
        return;

      root.remainingMs = Math.max(0, root.timerDeadline - Date.now());
      root.timerDeadline = 0;
      if (root.remainingMs > 0) {
        root.resumeTimer();
      } else {
        root.timerStarted = false;
        root.expireNative();
      }
    }
  }

  Timer {
    id: replacementTimer
    interval: 0
    onTriggered: root.replacement()
  }

  Timer {
    id: exitTimer
    interval: 300
    onTriggered: root.visualRemovalFinished()
  }

  Instantiator {
    model: root.data.actions || []

    delegate: Connections {
      required property var modelData
      target: modelData
      function onTextChanged() { root.syncAndScheduleReplacement(); }
    }
  }

  function syncAndScheduleReplacement() {
    root.syncFromNative();
    root.scheduleReplacement();
  }

  Connections {
    target: root.nativeNotification

    function onExpireTimeoutChanged() { root.syncAndScheduleReplacement(); }
    function onAppNameChanged() { root.syncAndScheduleReplacement(); }
    function onAppIconChanged() { root.syncAndScheduleReplacement(); }
    function onSummaryChanged() { root.syncAndScheduleReplacement(); }
    function onBodyChanged() { root.syncAndScheduleReplacement(); }
    function onUrgencyChanged() { root.syncAndScheduleReplacement(); }
    function onActionsChanged() { root.syncAndScheduleReplacement(); }
    function onHasActionIconsChanged() { root.syncAndScheduleReplacement(); }
    function onResidentChanged() { root.syncAndScheduleReplacement(); }
    function onImageChanged() { root.syncAndScheduleReplacement(); }
    function onHintsChanged() { root.syncAndScheduleReplacement(); }

    function onClosed() {
      root.syncFromNative();
      root.nativeClosed();
    }
  }
}
