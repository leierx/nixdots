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
  property bool moreOpen: false

  readonly property bool overflow: actions.length > 3

  visible: actions.length > 0
  spacing: 6

  component ActionButton: Rectangle {
    id: button

    property alias text: label.text
    // An expander arrow after the text, pointing up while open.
    property bool expander: false
    property bool open: false

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 34
    radius: Theme.buttonRadius
    color: area.containsMouse ? Theme.buttonHover : Theme.button

    Row {
      anchors.centerIn: parent
      spacing: 6

      Text {
        id: label

        width: Math.min(implicitWidth, button.width - 20 - (arrow.visible ? arrow.width + parent.spacing : 0))
        color: Theme.fg
        elide: Text.ElideRight
        font: Theme.heading
      }

      ExpanderArrow {
        id: arrow

        visible: button.expander
        anchors.verticalCenter: parent.verticalCenter
        open: button.open
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
    spacing: 6

    Repeater {
      model: root.overflow ? root.actions.slice(0, 2) : root.actions

      ActionButton {
        required property NotificationAction modelData

        text: modelData.text
        onClicked: modelData.invoke()
      }
    }

    ActionButton {
      visible: root.overflow
      text: "More"
      expander: true
      open: root.moreOpen
      onClicked: root.moreOpen = !root.moreOpen
    }
  }

  Repeater {
    model: root.overflow && root.moreOpen ? root.actions.slice(2) : []

    ActionButton {
      required property NotificationAction modelData

      text: modelData.text
      onClicked: modelData.invoke()
    }
  }
}
