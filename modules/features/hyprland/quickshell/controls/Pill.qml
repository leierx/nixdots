pragma ComponentBehavior: Bound

import QtQuick
import qs.common

// Shell's .quick-toggle: a pill, its menu arrow a segment of its own, a step lighter.
Rectangle {
  id: pill

  required property var toggle
  property bool open: false
  readonly property bool on: toggle.on
  readonly property color ink: on ? Theme.accentFg : Theme.fg
  readonly property color segmentBg: on ? Theme.accentSegmentBg : Theme.buttonHoverBg

  implicitHeight: Theme.toggleHeight
  height: Theme.toggleHeight
  radius: height / 2
  activeFocusOnTab: !toggle.unavailable
  Keys.onSpacePressed: Controls.flip(pill.toggle)
  Keys.onReturnPressed: pill.toggle.menu ? Controls.show(pill.toggle.key) : Controls.flip(pill.toggle)
  opacity: toggle.unavailable ? 0.5 : 1
  color: {
    if (on) return main.pressed ? Theme.accentActive : main.containsMouse ? Theme.accentHover : Theme.accentBg;
    return main.pressed ? Theme.buttonActiveBg : main.containsMouse ? Theme.buttonHoverBg : Theme.buttonBg;
  }

  Behavior on color {
    ColorAnimation {
      duration: Theme.quickTime
    }
  }

  Row {
    x: 15
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width - x - (segment.visible ? segment.width + 9 : Theme.padding)
    spacing: 9

    Glyph {
      anchors.verticalCenter: parent.verticalCenter
      path: pill.toggle.glyph
      size: 16
      color: pill.ink
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 25

      Text {
        width: parent.width
        text: pill.toggle.title
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: pill.ink
        font: Theme.heading
      }

      Text {
        width: parent.width
        visible: text !== ""
        text: pill.toggle.subtitle
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: pill.ink
        font: Theme.caption
      }
    }
  }

  MouseArea {
    id: main

    objectName: `pill:${pill.toggle.key}`
    width: parent.width - (segment.visible ? segment.width : 0)
    height: parent.height
    hoverEnabled: true
    enabled: !pill.toggle.unavailable
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: Controls.flip(pill.toggle)
  }

  Item {
    id: segment

    anchors.right: parent.right
    visible: pill.toggle.menu
    width: 38
    height: parent.height

    Rectangle {
      anchors.fill: parent
      anchors.leftMargin: 1
      topRightRadius: pill.radius
      bottomRightRadius: pill.radius
      color: side.containsMouse ? (pill.on ? Theme.accentSegmentHoverBg : Theme.segmentHoverBg) : pill.segmentBg

      Behavior on color {
        ColorAnimation {
          duration: Theme.quickTime
        }
      }
    }

    Rectangle {
      width: 1
      height: parent.height
      color: pill.on ? Theme.accentSeparator : Theme.segmentSeparator
    }

    ExpanderArrow {
      anchors.centerIn: parent
      pointing: pill.open ? "down" : "right"
      color: pill.ink
    }

    MouseArea {
      id: side

      objectName: `menu:${pill.toggle.key}`
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: Controls.show(pill.toggle.key)
    }

    TooltipArea {
      text: ({ wifi: "Wi-Fi Networks", vpn: "VPN Connections", bluetooth: "Bluetooth Devices", night: "Night Light Strength" })[pill.toggle.key] ?? `${pill.toggle.title} Menu`
    }
  }

  FocusRing {
    corner: pill.radius
    on: pill.activeFocus
  }
}
