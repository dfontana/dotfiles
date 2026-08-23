//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Hyprland

ShellRoot {
  Component.onCompleted: Hyprland.refreshToplevels()

  Variants {
    model: Quickshell.screens
    Bar {}
  }
}
