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
  property bool vrrActive: false
  property string updateCount: ""

  spacing: BarMetrics.gap

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

  function bluetoothText() {
    const devices = Bluetooth.devices.values;
    for (let index = 0; index < devices.length; index++) {
      const device = devices[index];
      if (!device.connected)
        continue;
      const battery = device.batteryAvailable ? ` ${Math.round(device.battery * 100)}%` : "";
      return `󰂱 ${device.name}${battery}`;
    }
    return "";
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

  BarPill {
    id: infoPill
    implicitWidth: infoRow.implicitWidth + BarMetrics.pillPadding * 2

    Row {
      id: infoRow
      anchors.centerIn: parent
      spacing: 5

      Text {
        color: root.vrrActive ? Theme.accent : Theme.muted
        font.family: Theme.iconFont
        font.pixelSize: 18
        text: root.vrrActive ? "󱧧" : "󰁪"
      }

      Text {
        id: updates
        visible: root.updatesEnabled
        anchors.verticalCenter: parent.verticalCenter
        color: updatesMouse.containsMouse ? Theme.accent : Theme.text
        font.family: Theme.iconFont
        font.pixelSize: 14
        font.weight: Font.DemiBold
        text: `  ${root.updateCount}`

        MouseArea {
          id: updatesMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: updatesTerminal.startDetached()
        }
      }
    }
  }

  PillButton {
    id: volumePill
    implicitWidth: volumeText.implicitWidth + BarMetrics.pillPadding * 2
    onClicked: volumeControl.startDetached()

    Text {
      id: volumeText
      anchors.centerIn: parent
      color: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted ? Theme.muted : Theme.accent
      font.family: Theme.iconFont
      font.pixelSize: 14
      font.weight: Font.DemiBold
      text: `${root.audioIcon()} 󰍭`
    }
  }

  BarPill {
    implicitWidth: bluetoothLabel.implicitWidth + BarMetrics.pillPadding * 2

    Text {
      id: bluetoothLabel
      anchors.centerIn: parent
      color: Theme.accent
      font.family: Theme.iconFont
      font.pixelSize: 14
      font.weight: Font.DemiBold
      text: root.bluetoothText()
    }
  }

  PillButton {
    id: clockPill
    implicitWidth: clockLabel.implicitWidth + BarMetrics.pillPadding * 2

    Text {
      id: clockLabel
      anchors.centerIn: parent
      color: Theme.accent
      font.family: Theme.iconFont
      font.pixelSize: 14
      font.weight: Font.DemiBold
      text: `${Qt.formatDateTime(clock.date, "ddd, dd MMM  HH:mm")} `
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
