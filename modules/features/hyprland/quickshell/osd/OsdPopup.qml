pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.bar
import qs.common

// What just changed on the focused screen, gone in a moment; clicks go through it.
Scope {
  id: root

  // Each kept through its own fade, which outlasts Osd.current.
  property var level: null
  property var tag: null

  // Material Symbols' mic, mic_off, headphones, speaker, light_mode and keyboard_capslock, filled
  readonly property string mic: "M480-400q-50 0-85-35t-35-85v-240q0-50 35-85t85-35q50 0 85 35t35 85v240q0 50-35 85t-85 35Zm-40 240v-83q-92-13-157.5-78T203-479q-2-17 9-29t28-12q17 0 28.5 11.5T284-480q14 70 69.5 115T480-320q72 0 127-45.5T676-480q4-17 15.5-28.5T720-520q17 0 28 12t9 29q-14 91-79 157t-158 79v83q0 17-11.5 28.5T480-120q-17 0-28.5-11.5T440-160Z"
  readonly property string micOff: "M672-377q-14-8-18-24.5t4-30.5q7-11 11.5-23.5T676-481q4-17 15.5-28t28.5-11q17 0 28 12t9 29q-3 23-10.5 45T727-392q-8 14-24.5 18.5T672-377ZM532-542 383-691q-11-11-17-25.5t-6-30.5v-13q0-50 35-85t85-35q50 0 85 35t35 85v189q0 27-24.5 37.5T532-542Zm-92 382v-84q-92-12-157.5-77T203-479q-2-17 9-29t28-12q17 0 28.5 11.5T284-480q14 70 69.5 115T480-320q34 0 64.5-10.5T600-360l57 57q-29 23-63.5 38.5T520-244v84q0 17-11.5 28.5T480-120q-17 0-28.5-11.5T440-160Zm324 76L84-764q-11-11-11-28t11-28q11-11 28-11t28 11l680 680q11 11 11 28t-11 28q-11 11-28 11t-28-11Z"
  readonly property string headphones: "M280-120h-80q-33 0-56.5-23.5T120-200v-280q0-75 28.5-140.5t77-114q48.5-48.5 114-77T480-840q75 0 140.5 28.5t114 77q48.5 48.5 77 114T840-480v280q0 33-23.5 56.5T760-120h-80q-33 0-56.5-23.5T600-200v-160q0-33 23.5-56.5T680-440h80v-40q0-117-81.5-198.5T480-760q-117 0-198.5 81.5T200-480v40h80q33 0 56.5 23.5T360-360v160q0 33-23.5 56.5T280-120Z"
  readonly property string speaker: "M680-80H280q-33 0-56.5-23.5T200-160v-640q0-33 23.5-56.5T280-880h400q33 0 56.5 23.5T760-800v640q0 33-23.5 56.5T680-80ZM480-600q33 0 56.5-23.5T560-680q0-33-23.5-56.5T480-760q-33 0-56.5 23.5T400-680q0 33 23.5 56.5T480-600Zm0 400q66 0 113-47t47-113q0-66-47-113t-113-47q-66 0-113 47t-47 113q0 66 47 113t113 47Zm0-80q-33 0-56.5-23.5T400-360q0-33 23.5-56.5T480-440q33 0 56.5 23.5T560-360q0 33-23.5 56.5T480-280Z"
  readonly property string sun: "M480-280q-83 0-141.5-58.5T280-480q0-83 58.5-141.5T480-680q83 0 141.5 58.5T680-480q0 83-58.5 141.5T480-280ZM80-440q-17 0-28.5-11.5T40-480q0-17 11.5-28.5T80-520h80q17 0 28.5 11.5T200-480q0 17-11.5 28.5T160-440H80Zm720 0q-17 0-28.5-11.5T760-480q0-17 11.5-28.5T800-520h80q17 0 28.5 11.5T920-480q0 17-11.5 28.5T880-440h-80ZM480-760q-17 0-28.5-11.5T440-800v-80q0-17 11.5-28.5T480-920q17 0 28.5 11.5T520-880v80q0 17-11.5 28.5T480-760Zm0 720q-17 0-28.5-11.5T440-80v-80q0-17 11.5-28.5T480-200q17 0 28.5 11.5T520-160v80q0 17-11.5 28.5T480-40ZM226-678l-43-42q-12-11-11.5-28t11.5-29q12-12 29-12t28 12l42 43q11 12 11 28t-11 28q-11 12-27.5 11.5T226-678Zm494 495-42-43q-11-12-11-28.5t11-27.5q11-12 27.5-11.5T734-282l43 42q12 11 11.5 28T777-183q-12 12-29 12t-28-12Zm-42-495q-12-11-11.5-27.5T678-734l42-43q11-12 28-11.5t29 11.5q12 12 12 29t-12 28l-43 42q-12 11-28 11t-28-11ZM183-183q-12-12-12-29t12-28l43-42q12-11 28.5-11t27.5 11q12 11 11.5 27.5T282-226l-42 43q-11 12-28 11.5T183-183Z"
  readonly property string caps: "M280-240q-17 0-28.5-11.5T240-280q0-17 11.5-28.5T280-320h400q17 0 28.5 11.5T720-280q0 17-11.5 28.5T680-240H280Zm200-384L324-468q-11 11-28 11t-28-11q-11-11-11-28t11-28l184-184q12-12 28-12t28 12l184 184q11 11 11 28t-11 28q-11 11-28 11t-28-11L480-624Z"

  function hasLevel(item: var): bool {
    return item?.level !== null && item?.level !== undefined;
  }

  function glyphOf(item: var): string {
    switch (item?.kind) {
    case undefined: return "";
    case "volume": return Volume.glyphFor(item.level, item.muted);
    case "microphone": return item.muted ? root.micOff : root.mic;
    case "input": return root.mic;
    case "output": return /head/i.test(item.title) ? root.headphones : root.speaker;
    case "brightness": return root.sun;
    default: return root.caps;
    }
  }

  function labelOf(item: var): string {
    switch (item?.kind) {
    case undefined: return "";
    case "microphone": return item.muted ? "Microphone Off" : "Microphone On";
    case "caps": return item.muted ? "Caps Lock Off" : "Caps Lock On";
    default: return item.title;
    }
  }

  function captionOf(item: var): string {
    switch (item?.kind) {
    case "output": return "Output";
    case "input": return "Input";
    case "microphone": return item.title;
    default: return "";
    }
  }

  Connections {
    target: Osd

    function onSerialChanged(): void {
      if (!Osd.current) return;
      if (root.hasLevel(Osd.current)) root.level = Osd.current;
      else root.tag = Osd.current;
    }
  }

  component Slider: Rectangle {
    id: slider

    readonly property real value: root.level?.level ?? 0
    readonly property bool dim: root.level?.muted ?? false

    implicitWidth: 52
    implicitHeight: 236
    radius: width / 2
    color: Theme.bg
    border.width: 1
    border.color: Theme.outline

    Shadow {}

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      y: 14
      text: Math.round(slider.value * 100)
      color: slider.dim ? Theme.fgDim : Theme.fg
      font: Theme.captionHeading
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      y: 38
      width: 8
      height: parent.height - 38 - 50
      radius: width / 2
      color: Theme.trough

      Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Math.max(parent.width, parent.height * Math.min(slider.value, 1))
        radius: parent.radius
        color: slider.dim ? Theme.fgDim : Theme.fg
        visible: slider.value > 0

        Behavior on height {
          NumberAnimation {
            duration: 100
          }
        }
      }

      // Past 100 %, the share over it from the top.
      Rectangle {
        visible: slider.value > 1
        width: parent.width
        height: parent.height * Math.min(slider.value - 1, 1) / Math.max(slider.value, 1)
        radius: parent.radius
        color: Theme.warning
      }
    }

    Glyph {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 15
      path: root.glyphOf(root.level)
      size: 22
      color: slider.dim ? Theme.fgDim : Theme.fg
    }
  }

  component Tag: Rectangle {
    implicitWidth: row.implicitWidth + 36
    implicitHeight: 52
    radius: height / 2
    color: Theme.bg
    border.width: 1
    border.color: Theme.outline

    Shadow {}

    Row {
      id: row

      anchors.centerIn: parent
      spacing: 12

      Glyph {
        anchors.verticalCenter: parent.verticalCenter
        path: root.glyphOf(root.tag)
        size: 22
        color: root.tag?.muted ? Theme.fgDim : Theme.fg
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter

        Text {
          text: root.labelOf(root.tag)
          color: Theme.fg
          font: Theme.heading
        }

        Text {
          visible: text !== ""
          text: root.captionOf(root.tag)
          color: Theme.fgDim
          font: Theme.caption
        }
      }
    }
  }

  component OsdWindow: PanelWindow {
    id: window

    required property ShellScreen modelData
    required property bool levels
    readonly property bool here: Osd.current !== null && Osd.screen === modelData?.name && root.hasLevel(Osd.current) === levels
    property real fade: 0

    // Not a Behavior: one whose duration follows `here` may start before that duration updates.
    onHereChanged: {
      (here ? fadeOut : fadeIn).stop();
      (here ? fadeIn : fadeOut).start();
    }

    screen: modelData
    visible: fade > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    // Nothing in it takes a click.
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    NumberAnimation {
      id: fadeIn

      target: window
      property: "fade"
      to: 1
      duration: 120
      easing.type: Easing.OutCubic
    }

    NumberAnimation {
      id: fadeOut

      target: window
      property: "fade"
      to: 0
      duration: 200
      easing.type: Easing.InOutQuad
    }
  }

  Variants {
    model: Screens.real

    Scope {
      id: output

      required property ShellScreen modelData

      // Levels by the right edge, words at the bottom as GNOME Shell shows them.
      OsdWindow {
        id: side

        modelData: output.modelData
        levels: true
        anchors.right: true
        // Room for the shadow, and 18 px off the edge.
        implicitWidth: slider.implicitWidth + 64 + 18
        implicitHeight: slider.implicitHeight + 64

        Slider {
          id: slider

          anchors.centerIn: parent
          anchors.horizontalCenterOffset: -9
          opacity: side.fade
        }
      }

      OsdWindow {
        id: below

        modelData: output.modelData
        levels: false
        anchors.bottom: true
        // Room for the shadow, and GNOME Shell's 4em off the edge.
        implicitWidth: tag.implicitWidth + 64
        implicitHeight: tag.implicitHeight + 32 + 4 * Theme.em

        Tag {
          id: tag

          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 4 * Theme.em
          opacity: below.fade
        }
      }
    }
  }
}
