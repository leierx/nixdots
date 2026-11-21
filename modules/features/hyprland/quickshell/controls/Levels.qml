pragma ComponentBehavior: Bound

import QtQuick
import qs.common
import qs.osd

Column {
  id: root

  // The menu open in the panel, which a level's arrow shows.
  property string menu: ""

  // A level: its symbol (a mute button where it mutes), the slider, and the arrow to its devices.
  component Level: Row {
    id: level

    property string name: ""
    property string glyph: ""
    property bool mutes: false
    property bool muted: false
    property real value: 0
    property string opens: ""

    signal moved(real value)
    signal stepped(int notches)
    signal muteClicked()

    spacing: 8

    IconButton {
      id: lead

      objectName: `mute:${level.name}`
      anchors.verticalCenter: parent.verticalCenter
      flat: true
      enabled: level.mutes && level.enabled
      checked: level.muted
      glyph: level.glyph
      onClicked: level.muteClicked()
    }

    Slider {
      objectName: `slider:${level.name}`
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - lead.width - arrow.width - 2 * parent.spacing
      enabled: level.enabled
      value: level.value
      dim: level.muted
      onMoved: value => level.moved(value)
      onStepped: notches => level.stepped(notches)
    }

    IconButton {
      id: arrow

      anchors.verticalCenter: parent.verticalCenter
      opacity: level.opens !== "" ? 1 : 0
      enabled: level.opens !== ""
      flat: true
      expander: true
      checked: level.opens !== "" && root.menu === level.opens
      pointing: checked ? "down" : "right"
      onClicked: Controls.show(level.opens)
    }
  }

  spacing: 6

  Row {
    visible: !Volume.present && !Microphone.present
    height: 34
    spacing: 8
    opacity: 0.5

    Item {
      width: 34
      height: 34

      Glyph {
        anchors.centerIn: parent
        path: Symbols.volumeOff
        size: 20
        color: Theme.fg
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "Sound not available"
      color: Theme.fg
      font: Theme.body
    }
  }

  Level {
    name: "output"
    width: parent.width
    visible: Volume.present
    glyph: Volume.glyph
    mutes: true
    muted: Volume.muted
    value: Volume.volume
    opens: "output"
    onMoved: value => Volume.setVolume(value)
    onStepped: notches => Volume.step(notches)
    onMuteClicked: Volume.toggleMute()
  }

  Level {
    name: "input"
    width: parent.width
    visible: Microphone.present
    // A virtual source has nothing to set; it stays in place, so nothing below moves.
    enabled: Microphone.adjustable
    opacity: Microphone.adjustable ? 1 : 0.5
    glyph: Microphone.glyph
    mutes: true
    muted: Microphone.muted
    value: Microphone.volume
    opens: "input"
    onMoved: value => Microphone.setVolume(value)
    onStepped: notches => Microphone.step(notches)
    onMuteClicked: Microphone.toggleMute()
  }

  Repeater {
    model: Object.keys(Brightness.devices)

    Level {
      id: backlight

      required property string modelData
      readonly property var device: Brightness.devices[modelData] ?? null

      name: `backlight:${modelData}`
      width: parent.width
      glyph: Symbols.brightness
      value: device ? device.brightness / device.max : 0
      onMoved: value => Brightness.set(backlight.modelData, value)
      onStepped: notches => Brightness.set(backlight.modelData, Math.round((backlight.value + notches * 0.05) * 20) / 20)
    }
  }
}
