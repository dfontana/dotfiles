// Development fallback for `qs -p quickshell/home`.
// Mise excludes this file from the deployed tree and renders the equivalent
// template from config/mise/templates/quickshell/home/theme/Theme.qml instead.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
  readonly property string name: "rose-pine-dawn"

  readonly property color base: "#faf4ed"
  readonly property color surface: "#fffaf3"
  readonly property color overlay: "#f2e9e1"
  readonly property color muted: "#9893a5"
  readonly property color subtle: "#797593"
  readonly property color text: "#575279"
  readonly property color love: "#b4637a"
  readonly property color gold: "#ea9d34"
  readonly property color rose: "#d7827e"
  readonly property color pine: "#286983"
  readonly property color foam: "#56949f"
  readonly property color iris: "#907aa9"
  readonly property color highlightLow: "#f4ede8"
  readonly property color highlightMed: "#dfdad9"
  readonly property color highlightHigh: "#cecacd"

  readonly property color barSurface: overlay
  readonly property color accent: rose
  readonly property color active: love
  readonly property color hover: highlightHigh
  readonly property string iconFont: "Iosevka Nerd Font"
}
