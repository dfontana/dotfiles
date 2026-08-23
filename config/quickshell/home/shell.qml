//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Hyprland

ShellRoot {
  Component.onCompleted: Hyprland.refreshToplevels()

  Launcher {}

  Variants {
    model: Quickshell.screens
    Bar {}
  }
}
