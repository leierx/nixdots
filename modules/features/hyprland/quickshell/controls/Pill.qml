pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.common

Rectangle {
  id: pill

  required property var toggle
  property bool open: false
  readonly property bool on: toggle.on
  readonly property color ink: on ? Theme.accentFg : Theme.fg
  // Shown at full strength, but nothing to click (an In Use pill whose app has no window).
  readonly property bool acts: !toggle.unavailable && !(toggle.inert ?? false)

  implicitHeight: Theme.toggleHeight
  height: Theme.toggleHeight
  radius: height / 2
  activeFocusOnTab: acts || activeFocus
  Keys.onSpacePressed: Controls.flip(pill.toggle)
  Keys.onReturnPressed: pill.toggle.menu ? Controls.show(pill.toggle.key) : Controls.flip(pill.toggle)
  opacity: toggle.unavailable ? 0.5 : 1

  Behavior on opacity {
    NumberAnimation {
      duration: Theme.quickTime
      easing.type: Easing.OutQuad
    }
  }

  color: "transparent"

  function fill(area: MouseArea): color {
    if (pill.on) return area.pressed ? Theme.accentActive : area.containsMouse ? Theme.accentHover : Theme.accentBg;
    return area.pressed ? Theme.buttonActiveBg : area.containsMouse ? Theme.buttonHoverBg : Theme.buttonBg;
  }

  // The toggle and its segment side by side in one pill-shaped clip: a fill of the segment alone could round its corners only to half its width, and laid over the toggle's, its colour stacked.
  ClippingRectangle {
    anchors.fill: parent
    radius: pill.radius
    color: "transparent"

    Rectangle {
      width: main.width
      height: parent.height
      color: pill.fill(main)

      Behavior on color {
        ColorAnimation {
          duration: Theme.quickTime
          easing.type: Easing.OutQuad
        }
      }
    }

    Rectangle {
      x: main.width
      width: parent.width - main.width
      height: parent.height
      color: pill.fill(side)

      Behavior on color {
        ColorAnimation {
          duration: Theme.quickTime
          easing.type: Easing.OutQuad
        }
      }
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
      color: pill.toggle.glyphColor ?? pill.ink
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
    enabled: pill.acts
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
      width: 1
      height: parent.height
      color: pill.on ? Theme.accentSeparator : Theme.segmentSeparator

      Behavior on color {
        ColorAnimation {
          duration: Theme.quickTime
          easing.type: Easing.OutQuad
        }
      }
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
