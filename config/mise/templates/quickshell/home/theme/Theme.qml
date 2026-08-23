pragma Singleton

import QtQuick
import Quickshell

Singleton {
  readonly property string name: "{{ vars.theme_name }}"

  readonly property color base: "{{ vars.theme_base }}"
  readonly property color surface: "{{ vars.theme_surface }}"
  readonly property color overlay: "{{ vars.theme_overlay }}"
  readonly property color muted: "{{ vars.theme_muted }}"
  readonly property color subtle: "{{ vars.theme_subtle }}"
  readonly property color text: "{{ vars.theme_text }}"
  readonly property color love: "{{ vars.theme_love }}"
  readonly property color gold: "{{ vars.theme_gold }}"
  readonly property color rose: "{{ vars.theme_rose }}"
  readonly property color pine: "{{ vars.theme_pine }}"
  readonly property color foam: "{{ vars.theme_foam }}"
  readonly property color iris: "{{ vars.theme_iris }}"
  readonly property color highlightLow: "{{ vars.theme_hl_low }}"
  readonly property color highlightMed: "{{ vars.theme_hl_med }}"
  readonly property color highlightHigh: "{{ vars.theme_hl_high }}"

  readonly property color barSurface: overlay
  readonly property color accent: rose
  readonly property color active: love
  readonly property color hover: highlightHigh
  readonly property string iconFont: "{{ vars.font_family_icon }}"
}
