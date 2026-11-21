pragma ComponentBehavior: Bound

import QtQuick
import qs.common

// GNOME's top row: the battery on the left, then a screenshot, the lock and the power menu.
Item {
  id: header

  function batteryState(): string {
    if (Power.charging) return Power.remaining > 0 ? `Full in ${Power.duration(Power.remaining)}` : "Charging";
    if (Power.plugged) return "Plugged in";
    return Power.remaining > 0 ? `${Power.duration(Power.remaining)} left` : "On battery";
  }


  implicitHeight: 34

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    visible: Power.present
    width: charge.width + 24
    height: 34
    radius: height / 2
    color: Theme.card

    Row {
      id: charge

      anchors.centerIn: parent
      spacing: 8

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

  Row {
    id: actions

    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: 8

    IconButton {
      objectName: "header:screenshot"
      glyph: Symbols.screenshot
      onClicked: Controls.screenshot()
    }

    IconButton {
      objectName: "header:lock"
      glyph: Symbols.lock
      onClicked: Controls.lock()
    }

    IconButton {
      objectName: "header:power"
      glyph: Symbols.power
      onClicked: Controls.powerMenu()
    }
  }
}
