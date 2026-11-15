pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.common

// A notification's buttons, three to a row; with more, the third opens the
// rest below.
ColumnLayout {
  id: root

  required property var actions
  // What the buttons rest on, and their colour under the pointer.
  property color base: Theme.raised
  property color hover: Theme.selected
  property bool moreOpen: false

  readonly property bool overflow: actions.length > 3

  visible: actions.length > 0
  spacing: Theme.px(4)

  component ActionButton: Rectangle {
    id: button

    property alias text: label.text
    property string glyph: ""

    signal clicked()

    implicitHeight: Theme.px(34)
    radius: Theme.px(8)
    color: area.containsMouse ? root.hover : root.base

    Row {
      anchors.centerIn: parent
      spacing: Theme.px(6)

      Text {
        id: label

        width: Math.min(implicitWidth, button.width - Theme.px(20) - (glyph.visible ? glyph.width + parent.spacing : 0))
        color: Theme.fg
        elide: Text.ElideRight
        font {
          family: Theme.fontFamily
          pixelSize: Theme.fontBody
        }
      }

      Text {
        id: glyph

        visible: button.glyph !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: button.glyph
        color: Theme.fgSoft
        font {
          family: Theme.glyphFamily
          pixelSize: Theme.fontBody
        }
      }
    }

    MouseArea {
      id: area

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.clicked()
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Theme.px(8)

    Repeater {
      model: root.overflow ? root.actions.slice(0, 2) : root.actions

      ActionButton {
        required property NotificationAction modelData

        Layout.fillWidth: true
        text: modelData.text
        onClicked: modelData.invoke()
      }
    }

    ActionButton {
      visible: root.overflow
      Layout.fillWidth: true
      text: "More"
      glyph: root.moreOpen ? "▴" : "▾"
      onClicked: root.moreOpen = !root.moreOpen
    }
  }

  Repeater {
    model: root.overflow && root.moreOpen ? root.actions.slice(2) : []

    ActionButton {
      required property NotificationAction modelData

      Layout.fillWidth: true
      text: modelData.text
      onClicked: modelData.invoke()
    }
  }
}
