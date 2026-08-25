//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.widgets.notifications

ShellRoot {
  Component.onCompleted: Hyprland.refreshToplevels()

  NotificationService {
    id: notificationController
  }

  NotificationStack {
    service: notificationController
  }

  Launcher {}

  Variants {
    model: Quickshell.screens

    Bar {
      notificationService: notificationController
    }
  }
}
