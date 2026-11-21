pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.controls
import qs.common

// What just changed on the focused screen, gone in a moment; clicks go through it.
Scope {
  id: root

  // Each kept through its own fade, which outlasts Osd.current.
  property var level: null
  property var tag: null


  function hasLevel(item: var): bool {
    return item?.level !== null && item?.level !== undefined;
  }

  function glyphOf(item: var): string {
    switch (item?.kind) {
    case undefined: return "";
    case "volume": return Volume.glyphFor(item.level, item.muted);
    case "microphone": return item.muted ? Symbols.micOff : Symbols.mic;
    case "input": return Symbols.mic;
    case "output": return /head/i.test(item.title) ? Symbols.headphones : Symbols.speaker;
    case "brightness": return Symbols.brightness;
    default: return Symbols.capsLock;
    }
  }

  function labelOf(item: var): string {
    switch (item?.kind) {
    case undefined: return "";
    case "caps": return item.muted ? "Caps Lock Off" : "Caps Lock On";
    default: return item.title;
    }
  }

  function captionOf(item: var): string {
    switch (item?.kind) {
    case "output": return "Output";
    case "input": return "Input";
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

  component Meter: Card {
    id: slider

    readonly property real value: root.level?.level ?? 0
    readonly property bool dim: root.level?.muted ?? false

    implicitWidth: 52
    implicitHeight: 236
    radius: width / 2

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
            duration: Theme.move
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

  component Tag: Card {
    implicitWidth: row.implicitWidth + 36
    implicitHeight: 52
    radius: height / 2

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
    // Taken once: the screen object dangles while its monitor goes.
    property string screenName: ""
    readonly property bool here: Osd.current !== null && Osd.screen === screenName && root.hasLevel(Osd.current) === levels
    property real fade: here ? 1 : 0

    Behavior on fade {
      NumberAnimation {
        duration: Theme.fade
        easing.type: Easing.OutCubic
      }
    }

    Component.onCompleted: screenName = modelData?.name ?? ""
    screen: modelData
    visible: fade > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    // Nothing in it takes a click.
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
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

        Meter {
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
