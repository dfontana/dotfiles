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
    presentationBlocked: launcherController.launcherOpen
  }

  Launcher {
    id: launcherController
  }

  Variants {
    model: Quickshell.screens

    Bar {
      launcherService: launcherController
      notificationService: notificationController
    }
  }
}
