pragma ComponentBehavior: Bound

import QtQuick
import qs.common
import qs.nix
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
    property real maximum: 1
    property string opens: ""
    readonly property real span: track.span

    signal moved(real value)
    signal stepped(int notches)
    signal muteClicked()

    spacing: Theme.basePadding

    IconButton {
      id: lead

      objectName: `mute:${level.name}`
      anchors.verticalCenter: parent.verticalCenter
      small: true
      flat: true
      // Only its click is off where nothing mutes: the symbol still names the level.
      opacity: 1
      enabled: level.mutes && level.enabled
      checked: level.muted
      glyph: level.glyph
      tooltip: level.mutes ? (level.muted ? "Unmute" : "Mute") : ""
      onClicked: level.muteClicked()
    }

    Slider {
      id: track

      objectName: `slider:${level.name}`
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - lead.width - arrow.width - 2 * parent.spacing
      enabled: level.enabled
      value: level.value
      maximum: level.maximum
      dim: level.muted
      onMoved: value => level.moved(value)
      onStepped: notches => level.stepped(notches)
    }

    IconButton {
      id: arrow

      anchors.verticalCenter: parent.verticalCenter
      opacity: level.opens !== "" ? 1 : 0
      enabled: level.opens !== ""
      small: true
      flat: true
      expander: true
      checked: level.opens !== "" && root.menu === level.opens
      pointing: checked ? "down" : "right"
      tooltip: level.opens === "sound" ? "Sound" : ""
      onClicked: Controls.show(level.opens)
    }
  }

  spacing: Theme.basePadding

  Row {
    visible: !Volume.present
    height: 28
    spacing: Theme.basePadding
    opacity: 0.5

    Item {
      width: 28
      height: 28

      Glyph {
        anchors.centerIn: parent
        path: Symbols.volumeOff
        size: 16
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
    maximum: Volume.volume
    opens: "sound"
    onMoved: value => Volume.setVolume(value, span)
    onStepped: notches => Volume.step(notches)
    onMuteClicked: Volume.toggleMute()
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
