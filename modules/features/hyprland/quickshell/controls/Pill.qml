pragma ComponentBehavior: Bound

import QtQuick
import qs.common

// GNOME's quick toggle: a pill, its arrow a segment of its own.
Rectangle {
  id: pill


  required property var toggle
  property bool open: false
  property color ink: toggle.on ? Theme.accentFg : Theme.fg
  property color dimInk: toggle.on ? Theme.accentFg : Theme.fgDim
  property color rule: toggle.on ? Theme.accentFg : Theme.border

  height: 48
  radius: height / 2
  opacity: toggle.unavailable ? 0.5 : 1
  color: toggle.on ? Theme.accentBg : Theme.button

  Behavior on color {
    ColorAnimation {
      duration: Theme.fade
    }
  }

  Behavior on ink {
    ColorAnimation {
      duration: Theme.fade
    }
  }

  Behavior on dimInk {
    ColorAnimation {
      duration: Theme.fade
    }
  }

  Behavior on rule {
    ColorAnimation {
      duration: Theme.fade
    }
  }

  Behavior on opacity {
    NumberAnimation {
      duration: Theme.fade
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: main.containsMouse && main.enabled ? Theme.hover : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: Theme.fade
      }
    }
  }

  // A flip's feedback: a ripple spreading from the click, and the symbol's Pop.
  function pop(x: real): void {
    ripple.from = Math.max(0, Math.min(pill.width - pill.height, x - pill.height / 2));
    popping.restart();
  }

  Rectangle {
    id: ripple

    property real from: 0

    height: parent.height
    radius: height / 2
    color: Theme.fg
    opacity: 0
  }

  ParallelAnimation {
    id: popping

    NumberAnimation {
      target: ripple
      property: "x"
      from: ripple.from
      to: 0
      duration: Theme.settle
      easing.type: Easing.OutCubic
    }

    NumberAnimation {
      target: ripple
      property: "width"
      from: pill.height
      to: pill.width
      duration: Theme.settle
      easing.type: Easing.OutCubic
    }

    NumberAnimation {
      target: ripple
      property: "opacity"
      from: 0.25
      to: 0
      duration: Theme.settle
      easing.type: Easing.OutCubic
    }

    Pop {
      target: symbol
    }
  }

  Row {
    x: 14
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width - x - (segment.visible ? segment.width : 14)
    spacing: 10

    Glyph {
      id: symbol

      anchors.verticalCenter: parent.verticalCenter
      path: pill.toggle.glyph
      size: 16
      color: pill.ink
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 30

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
        text: pill.toggle.subtitle
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: pill.dimInk
        opacity: pill.toggle.on ? 0.8 : 1

        Behavior on opacity {
          NumberAnimation {
            duration: Theme.fade
          }
        }
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
    onClicked: mouse => {
      Controls.flip(pill.toggle);
      pill.pop(mouse.x);
    }
  }

  Item {
    id: segment

    anchors.right: parent.right
    visible: pill.toggle.menu
    width: 44
    height: parent.height

    Rectangle {
      width: 1
      height: parent.height - 20
      anchors.verticalCenter: parent.verticalCenter
      color: pill.rule
      opacity: pill.toggle.on ? 0.3 : 1

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.fade
        }
      }
    }

    Rectangle {
      anchors.fill: parent
      anchors.leftMargin: 1
      topRightRadius: pill.radius
      bottomRightRadius: pill.radius
      color: side.containsMouse ? Theme.hover : "transparent"

      Behavior on color {
        ColorAnimation {
          duration: Theme.fade
        }
      }
    }

    ExpanderArrow {
      anchors.centerIn: parent
      anchors.horizontalCenterOffset: -2
      pointing: pill.open ? "down" : "right"
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
}
