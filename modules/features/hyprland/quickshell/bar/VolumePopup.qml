pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// libadwaita's popover under the volume button: the output and the input, each a level with mute beside it and the devices to pick from.
Overlay {
  id: root

  required property real anchorX
  // The bar's height, which the popup drops below.
  required property real top
  // Material Symbols' check
  readonly property string check: "m382-354 339-339q12-12 28-12t28 12q12 12 12 28.5T777-636L410-268q-12 12-28 12t-28-12L182-440q-12-12-11.5-28.5T183-497q12-12 28.5-12t28.5 12l142 143Z"

  card: box
  // Shown over its bar without dimming the screen behind.
  WlrLayershell.namespace: "quickshell:volume"

  // Volume or Microphone.
  component Slider: Item {
    id: slider

    required property var backend
    // Past 100 %, set by another app, it reads full.
    readonly property real value: Math.min(1, backend.volume)

    implicitHeight: 26

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: 6
      radius: height / 2
      color: Theme.trough

      Rectangle {
        width: parent.width * slider.value
        height: parent.height
        radius: parent.radius
        color: slider.backend.muted ? Theme.fgDim : Theme.accentBg
      }
    }

    Rectangle {
      x: slider.value * (slider.width - width)
      anchors.verticalCenter: parent.verticalCenter
      width: 20
      height: 20
      radius: height / 2
      color: Theme.slider
      scale: drag.pressed ? 1.1 : 1

      Behavior on scale {
        NumberAnimation {
          duration: 100
        }
      }
    }

    MouseArea {
      id: drag

      anchors.fill: parent
      // Set from the slider, which reads its own; a disabled ancestor leaves it reading true.
      enabled: slider.enabled
      cursorShape: !enabled ? Qt.ArrowCursor : pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
      onPressed: mouse => slider.backend.setVolume(mouse.x / width)
      onPositionChanged: mouse => {
        if (pressed) slider.backend.setVolume(mouse.x / width);
      }
      onWheel: event => {
        const steps = notches.steps(event);
        if (steps !== 0) slider.backend.step(steps);
      }
    }

    WheelSteps {
      id: notches
    }
  }

  component Level: Row {
    id: level

    required property var backend
    // A virtual source has nothing to set; it stays in place, so the list below never moves.
    readonly property bool adjustable: backend.adjustable ?? true

    spacing: 10
    opacity: adjustable ? 1 : 0.5

    Button {
      id: muteButton

      anchors.verticalCenter: parent.verticalCenter
      radius: height / 2
      padding: 0
      enabled: level.adjustable
      checked: level.backend.muted
      glyph: level.backend.glyph
      glyphSize: 20
      onClicked: level.backend.toggleMute()
    }

    Slider {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - muteButton.width - percent.width - 2 * parent.spacing
      enabled: level.adjustable
      backend: level.backend
    }

    Text {
      id: percent

      anchors.verticalCenter: parent.verticalCenter
      width: 36
      horizontalAlignment: Text.AlignRight
      text: level.adjustable ? `${level.backend.percent}%` : ""
      color: level.backend.muted ? Theme.fgDim : Theme.fg
      font: Theme.heading
    }
  }

  component Caption: Text {
    leftPadding: 4
    color: Theme.fgDim
    font: Theme.captionHeading
  }

  // The devices, the one in use ticked; scrolled once taller than `limit`.
  component Devices: Flickable {
    id: devices

    required property var backend
    property real limit: contentHeight

    height: Math.min(contentHeight, Math.max(32, limit))
    contentHeight: rows.implicitHeight
    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    Column {
      id: rows

      width: devices.width

      Repeater {
        model: devices.backend.devices

        Rectangle {
          id: row

          required property var modelData

          width: rows.width
          height: 32
          radius: Theme.smallRadius
          color: rowArea.containsMouse ? Theme.hover : "transparent"

          Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 10
            width: parent.width - 44
            text: row.modelData.name
            elide: Text.ElideRight
            color: Theme.fg
            font: row.modelData.current ? Theme.heading : Theme.body
          }

          Glyph {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 10
            visible: row.modelData.current
            path: root.check
            size: 18
            color: Theme.accent
          }

          MouseArea {
            id: rowArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: row.modelData.current ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: devices.backend.choose(row.modelData.index)
          }
        }
      }
    }
  }

  Card {
    id: box

    // What the screen leaves the two lists, below everything else in the card.
    readonly property real room: root.height - root.top - 2 * Theme.gap - 2 * Theme.padding - outputCaption.height - outputLevel.height - (input.visible ? rule.height + inputCaption.height + inputLevel.height + 4 * column.spacing : 0) - 2 * column.spacing
    readonly property real wantsOut: outputs.contentHeight
    readonly property real wantsIn: input.visible ? inputs.contentHeight : 0

    x: Math.max(Theme.gap, Math.min(root.anchorX - width / 2, root.width - width - Theme.gap))
    y: root.top + Theme.gap
    width: Math.round(20 * Theme.em)
    height: column.implicitHeight + 2 * Theme.padding
    radius: Theme.cardRadius
    focus: true

    Column {
      id: column

      x: Theme.padding
      y: Theme.padding
      width: parent.width - 2 * Theme.padding
      spacing: 10

      Caption {
        id: outputCaption

        text: "Output"
      }

      Level {
        id: outputLevel

        width: parent.width
        backend: Volume
      }

      // Each list gets all it wants while both fit, otherwise the shorter keeps its own up to half.
      Devices {
        id: outputs

        width: parent.width
        backend: Volume
        limit: box.wantsOut + box.wantsIn <= box.room ? box.wantsOut : box.room - Math.min(box.wantsIn, box.room / 2)
      }

      Column {
        id: input

        width: parent.width
        visible: Microphone.present
        spacing: column.spacing

        Rectangle {
          id: rule

          width: parent.width
          height: 1
          color: Theme.border
        }

        Caption {
          id: inputCaption

          text: "Input"
        }

        Level {
          id: inputLevel

          width: parent.width
          backend: Microphone
        }

        Devices {
          id: inputs

          width: parent.width
          backend: Microphone
          limit: box.wantsOut + box.wantsIn <= box.room ? box.wantsIn : box.room - Math.min(box.wantsOut, box.room / 2)
        }
      }
    }
  }
}
