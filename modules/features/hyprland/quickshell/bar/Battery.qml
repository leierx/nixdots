pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common

// A thick meter with its percentage on it, the lettering dark over the fill and light past it.
Item {
  id: root

  required property ShellScreen screen
  readonly property real level: Math.max(0, Math.min(Power.percent, 100)) / 100
  readonly property color fill: Power.critical ? Theme.destructive : Power.low ? Theme.warning : Theme.success
  // Material Symbols' bolt, filled
  readonly property string bolt: "M360-360H236q-24 0-35.5-21.5T203-423l299-430q10-14 26-19.5t33 .5q17 6 25 21t6 32l-32 259h155q26 0 36.5 23t-6.5 43L416-100q-11 13-27 17t-31-3q-15-7-23.5-21.5T328-139l32-221Z"

  visible: Power.present
  implicitWidth: body.width + 3 + 12
  implicitHeight: 26

  component Lettering: Row {
    property color color: Theme.fg

    anchors.centerIn: parent
    spacing: 1

    Glyph {
      anchors.verticalCenter: parent.verticalCenter
      visible: Power.plugged
      path: root.bolt
      size: 11
      color: parent.color
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Power.percent
      color: parent.color
      font: Qt.font({ family: Theme.body.family, pointSize: 8, weight: Font.Bold })
    }
  }

  Rectangle {
    id: body

    x: 6
    anchors.verticalCenter: parent.verticalCenter
    width: 38
    height: 17
    radius: 5
    color: Theme.trough
    clip: true

    Lettering {}

    Rectangle {
      id: filled

      width: Math.max(4, parent.width * root.level)
      height: parent.height
      radius: parent.radius
      color: root.fill
      clip: true

      Behavior on width {
        NumberAnimation {
          duration: 400
          easing.type: Easing.OutCubic
        }
      }

      Item {
        width: body.width
        height: body.height

        Lettering {
          color: Theme.panel
        }
      }
    }
  }

  Rectangle {
    anchors.left: body.right
    anchors.leftMargin: 1
    anchors.verticalCenter: body.verticalCenter
    width: 2
    height: 7
    radius: 1
    color: root.level >= 0.99 ? root.fill : Theme.trough
  }

  HoverHandler {
    id: hover
  }

  Tooltip {
    anchorItem: root
    screen: root.screen
    shown: hover.hovered && root.visible

    Column {
      spacing: 2

      Text {
        text: Power.charging ? (Power.remaining > 0 ? `Full in ${Power.duration(Power.remaining)}` : "Charging") : Power.plugged ? "Plugged in" : Power.remaining > 0 ? `${Power.duration(Power.remaining)} left` : "On battery"
        color: Theme.fg
        font: Theme.heading
      }

      Text {
        text: `${Power.percent} % · ${Power.charging ? "charging" : Power.plugged ? "not charging" : "on battery"}`
        color: Theme.fgDim
        font: Theme.caption
      }
    }
  }
}
