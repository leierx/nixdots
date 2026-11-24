pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.common
import qs.nix

Item {
  id: header

  function batteryState(): string {
    if (Power.charging) return Power.remaining > 0 ? `Full in about ${Power.duration(Power.remaining)}` : "Charging";
    if (Power.plugged) return "Plugged in";
    return Power.remaining > 0 ? `About ${Power.duration(Power.remaining)} left` : "On battery";
  }

  readonly property bool bare: !Power.present && Machine.hostname !== ""

  implicitHeight: Theme.iconButtonSize

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    visible: Power.present
    width: charge.width + 2 * Theme.padding
    height: Theme.iconButtonSize
    radius: height / 2
    color: Theme.buttonBg

    Row {
      id: charge

      anchors.centerIn: parent
      spacing: Theme.basePadding

      BatteryGlyph {
        anchors.verticalCenter: parent.verticalCenter
        level: Power.percent / 100
        charging: Power.charging
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, header.width - actions.width - 56)
        text: `${Theme.unit(Power.percent, "%")} · ${header.batteryState()}`
        elide: Text.ElideRight
        color: Theme.fg
        font: Theme.body
      }
    }
  }

  // Where there is no battery, the machine: bare, as nothing here is a button.
  Row {
    x: Theme.basePadding
    anchors.verticalCenter: parent.verticalCenter
    visible: header.bare
    spacing: Theme.basePadding

    IconImage {
      anchors.verticalCenter: parent.verticalCenter
      implicitSize: 24
      source: Machine.icon
    }

    Text {
      id: host

      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, header.width - actions.width - 2 * Theme.padding - 24)
      text: Machine.hostname
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: Theme.fg
      font: Theme.heading
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, Math.min(implicitWidth, header.width - actions.width - 2 * Theme.padding - 24 - host.width - 2 * Theme.basePadding))
      visible: Machine.uptime !== ""
      text: `· ${Machine.uptime}`
      elide: Text.ElideRight
      color: Theme.fgDim
      font: Theme.body
    }
  }

  Row {
    id: actions

    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.padding

    IconButton {
      objectName: "header:screenshot"
      glyph: Symbols.screenshot
      tooltip: "Take Screenshot"
      onClicked: Controls.screenshot()
    }

    IconButton {
      objectName: "header:lock"
      glyph: Symbols.lock
      tooltip: "Lock"
      onClicked: Controls.lock()
    }

    IconButton {
      objectName: "header:power"
      glyph: Symbols.power
      tooltip: "Power Menu"
      onClicked: Controls.powerMenu()
    }
  }
}
