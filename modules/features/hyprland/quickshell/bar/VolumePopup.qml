pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// libadwaita's popover under the volume button: a slider with mute beside it, then the outputs to pick from.
Overlay {
  id: root

  required property real anchorX
  // The bar's height, which the popup drops below.
  required property real top
  required property string glyph
  // Material Symbols' check
  readonly property string check: "m382-354 339-339q12-12 28-12t28 12q12 12 12 28.5T777-636L410-268q-12 12-28 12t-28-12L182-440q-12-12-11.5-28.5T183-497q12-12 28.5-12t28.5 12l142 143Z"

  card: box
  // Shown over its bar without dimming the screen behind.
  WlrLayershell.namespace: "quickshell:volume"

  component Slider: Item {
    id: slider

    // Past 100 %, set by another app, it reads full.
    readonly property real value: Math.min(1, Volume.volume)

    implicitHeight: 26

    Rectangle {
      id: trough

      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: 6
      radius: 3
      color: Theme.trough

      Rectangle {
        width: parent.width * slider.value
        height: parent.height
        radius: parent.radius
        color: Volume.muted ? Theme.fgDim : Theme.accentBg
      }
    }

    Rectangle {
      x: slider.value * (slider.width - width)
      anchors.verticalCenter: parent.verticalCenter
      width: 20
      height: 20
      radius: 10
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
      cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
      onPressed: mouse => Volume.setVolume(mouse.x / width)
      onPositionChanged: mouse => {
        if (pressed) Volume.setVolume(mouse.x / width);
      }
      onWheel: event => {
        const steps = notches.steps(event);
        if (steps !== 0) Volume.step(steps);
      }
    }

    WheelSteps {
      id: notches
    }
  }

  Card {
    id: box

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

      Row {
        width: parent.width
        spacing: 10

        Rectangle {
          id: muteButton

          anchors.verticalCenter: parent.verticalCenter
          width: 34
          height: 34
          radius: 17
          color: Volume.muted ? Theme.buttonChecked : muteArea.containsMouse ? Theme.buttonHover : Theme.button

          Glyph {
            anchors.centerIn: parent
            path: root.glyph
            size: 20
          }

          MouseArea {
            id: muteArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Volume.toggleMute()
          }
        }

        Slider {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - muteButton.width - percent.width - 2 * parent.spacing
        }

        Text {
          id: percent

          anchors.verticalCenter: parent.verticalCenter
          width: 36
          horizontalAlignment: Text.AlignRight
          text: `${Volume.percent}%`
          color: Volume.muted ? Theme.fgDim : Theme.fg
          font: Theme.heading
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
      }

      Text {
        leftPadding: 4
        text: "Output"
        color: Theme.fgDim
        font: Theme.captionHeading
      }

      Column {
        width: parent.width

        Repeater {
          model: Volume.devices

          Rectangle {
            id: row

            required property var modelData

            width: parent.width
            height: 34
            radius: Theme.buttonRadius
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
              onClicked: Volume.choose(row.modelData.index)
            }
          }
        }
      }
    }
  }
}
