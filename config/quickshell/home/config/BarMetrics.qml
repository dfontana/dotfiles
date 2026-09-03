pragma Singleton

import Quickshell

Singleton {
  // Shared legacy component metrics; island geometry uses compact* values.
  readonly property int height: 30
  readonly property int margin: 7
  readonly property int gap: 9
  readonly property int pillPadding: 10
  readonly property int animationDuration: 300
  readonly property int iconButtonWidth: 34

  readonly property int compactTopOffset: 7
  readonly property int compactHeight: 36
  readonly property int compactRadius: 12
  readonly property int compactHorizontalPadding: 6
  readonly property int compactVerticalPadding: 4
  readonly property int compactSlotSize: 28
  readonly property int compactItemGap: 2
  readonly property int compactHoverRadius: 8
  readonly property int compactHoverDuration: 100
  readonly property int compactSeparatorHeight: 18
  readonly property int compactSeparatorMargin: 5
  readonly property int compactFootprint: compactTopOffset + compactHeight
  readonly property string primaryOutput: "DP-1"
}
