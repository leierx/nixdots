pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common

// What is recording, in the bar only while something is: a button's grey pill, the bar's symbols
// and a breathing recording light. Hovering it says who.
Item {
  id: root

  required property QsWindow window

  visible: Privacy.kinds.length > 0
  implicitWidth: visible ? pill.implicitWidth + 6 : 0
  implicitHeight: 26

  HoverHandler {
    id: hover
  }

  Rectangle {
    id: pill

    anchors.centerIn: parent
    implicitWidth: row.implicitWidth + 18
    implicitHeight: 24
    radius: height / 2
    color: hover.hovered ? Theme.buttonHover : Theme.button

    Behavior on color {
      ColorAnimation {
        duration: 150
      }
    }

    Row {
      id: row

      anchors.centerIn: parent
      spacing: 7

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 8
        radius: 4
        color: Theme.recording

        SequentialAnimation on opacity {
          loops: Animation.Infinite
          running: root.visible

          NumberAnimation {
            to: 0.35
            duration: 900
            easing.type: Easing.InOutSine
          }

          NumberAnimation {
            to: 1
            duration: 900
            easing.type: Easing.InOutSine
          }
        }
      }

      Row {
        id: symbols

        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Repeater {
          model: Privacy.kinds

          Glyph {
            required property var modelData

            y: (symbols.height - height) / 2
            path: modelData.glyph
            size: 15
            color: Theme.fg
          }
        }
      }
    }
  }

  PrivacyTooltip {
    anchorItem: root
    window: root.window
    shown: hover.hovered && root.visible
  }
}
