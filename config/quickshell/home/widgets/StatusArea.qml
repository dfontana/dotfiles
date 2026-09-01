import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.components
import qs.config
import qs.theme

Row {
  id: root

  required property string outputName
  required property bool updatesEnabled
  required property var notificationService
  property var screen: null
  property bool vrrActive: false
  property string updateCount: ""
  readonly property var connectedBluetoothDevice: {
    const devices = Bluetooth.devices.values;
    for (let index = 0; index < devices.length; index++) {
      if (devices[index].connected)
        return devices[index];
    }
    return null;
  }

  spacing: BarMetrics.compactItemGap

  function pollVrr() {
    if (root.outputName.length === 0 || vrrProcess.running)
      return;
    root.vrrActive = false;
    vrrProcess.running = true;
  }

  function refreshUpdates() {
    if (root.updatesEnabled && !updatesProcess.running)
      updatesProcess.running = true;
  }

  function audioIcon() {
    const sink = Pipewire.defaultAudioSink;
    if (!sink || !sink.audio || sink.audio.volume === 0)
      return "";
    if (sink.audio.muted)
      return "";
    if (sink.audio.volume <= 0.33)
      return "";
    if (sink.audio.volume <= 0.66)
      return "";
    return "";
  }

  Component.onCompleted: {
    root.pollVrr();
    root.refreshUpdates();
  }
  onOutputNameChanged: root.pollVrr()
  onUpdatesEnabledChanged: root.refreshUpdates()

  Process {
    id: vrrProcess
    command: ["vrr-status", root.outputName]

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.vrrActive = JSON.parse(text).percentage > 0;
        } catch (_) {
          root.vrrActive = false;
        }
      }
    }
  }

  Timer {
    interval: 10000
    repeat: true
    running: root.outputName.length > 0
    onTriggered: root.pollVrr()
  }

  Process {
    id: updatesProcess
    command: ["sh", "-c", "dnf check-update -q | wc -l"]

    stdout: StdioCollector {
      onStreamFinished: root.updateCount = text.trim()
    }
  }

  Timer {
    interval: 3600000
    repeat: true
    running: root.updatesEnabled
    onTriggered: root.refreshUpdates()
  }

  Process {
    id: updatesTerminal
    command: ["kitty", "--hold", "--detach", "dnf", "check-update"]
  }

  Process {
    id: volumeControl
    command: ["pavucontrol"]
  }

  CompactIconButton {
    icon: root.vrrActive ? "󱧧" : "󰁪"
    iconSize: 18
    iconColor: root.vrrActive ? Theme.accent : Theme.muted
    interactive: false
  }

  CompactIconButton {
    visible: root.updatesEnabled
    icon: ""
    iconSize: 15
    iconColor: Number(root.updateCount) > 0 ? Theme.accent : Theme.text
    indicatorVisible: Number(root.updateCount) > 0
    onClicked: updatesTerminal.startDetached()
  }

  CompactIconButton {
    icon: root.audioIcon()
    iconSize: 16
    iconColor: Pipewire.defaultAudioSink
      && Pipewire.defaultAudioSink.audio
      && Pipewire.defaultAudioSink.audio.muted
      ? Theme.muted
      : Theme.text
    onClicked: volumeControl.startDetached()
  }

  CompactIconButton {
    icon: root.connectedBluetoothDevice ? "󰂱" : ""
    iconSize: 16
    iconColor: root.connectedBluetoothDevice ? Theme.accent : Theme.muted
    indicatorVisible: root.connectedBluetoothDevice !== null
    interactive: false
  }

  CompactIconButton {
    icon: "󰂚"
    iconSize: 16
    iconColor: !root.notificationService || !root.notificationService.hasNotifications
      ? Theme.muted
      : root.notificationService.stackVisible ? Theme.active : Theme.text
    indicatorVisible: root.notificationService && root.notificationService.hasNotifications
    indicatorColor: Theme.active
    onClicked: {
      if (root.notificationService)
        root.notificationService.toggleFor(root.screen);
    }
  }

  Item {
    id: clock

    readonly property bool hovered: clockHover.hovered
    property string timeText: ""
    property string dateText: ""

    implicitWidth: clockRow.implicitWidth
    implicitHeight: BarMetrics.compactSlotSize

    function pad(value, width) {
      return ("0000" + value).slice(-width);
    }

    function refresh() {
      const now = new Date();
      clock.timeText = clock.pad(now.getHours(), 2) + ":"
        + clock.pad(now.getMinutes(), 2);
      clock.dateText = clock.pad(now.getFullYear(), 4) + "-"
        + clock.pad(now.getMonth() + 1, 2) + "-"
        + clock.pad(now.getDate(), 2);
      minuteTimer.interval = 60000
        - now.getSeconds() * 1000
        - now.getMilliseconds();
      minuteTimer.restart();
    }

    Component.onCompleted: clock.refresh()

    Timer {
      id: minuteTimer

      repeat: false
      onTriggered: clock.refresh()
    }

    HoverHandler {
      id: clockHover
    }

    Rectangle {
      anchors.fill: parent
      radius: BarMetrics.compactHoverRadius
      color: clock.hovered ? Theme.hover : "transparent"

      Behavior on color {
        ColorAnimation {
          duration: BarMetrics.compactHoverDuration
        }
      }
    }

    Row {
      id: clockRow

      anchors.centerIn: parent
      height: BarMetrics.compactSlotSize
      spacing: 0

      Text {
        id: timeLabel

        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text
        font.family: Theme.iconFont
        font.pixelSize: 13
        text: clock.timeText
      }

      Item {
        id: dateReveal

        clip: true
        width: clock.hovered
          ? BarMetrics.compactItemGap + dateLabel.implicitWidth
          : 0
        height: parent.height

        Behavior on width {
          NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
          }
        }

        Text {
          id: dateLabel

          x: BarMetrics.compactItemGap
          anchors.verticalCenter: parent.verticalCenter
          color: Theme.text
          font.family: Theme.iconFont
          font.pixelSize: 13
          opacity: clock.hovered ? 1 : 0
          text: clock.dateText

          Behavior on opacity {
            NumberAnimation {
              duration: 180
              easing.type: Easing.OutCubic
            }
          }
        }
      }
    }
  }
}
