pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.common

ColumnLayout {
  id: root

  required property var actions
  property bool moreOpen: false

  readonly property bool overflow: actions.length > 3

  signal invoked(NotificationAction action)

  visible: actions.length > 0
  spacing: 6

  component ActionButton: Button {
    required property NotificationAction modelData

    Layout.fillWidth: true
    // Equal shares, whatever their labels.
    Layout.preferredWidth: 1
    text: modelData?.text ?? ""
    onClicked: if (modelData) root.invoked(modelData)
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: 6

    Repeater {
      model: root.overflow ? root.actions.slice(0, 2) : root.actions

      ActionButton {}
    }

    Button {
      Layout.fillWidth: true
      Layout.preferredWidth: 1
      visible: root.overflow
      text: "More"
      expander: true
      open: root.moreOpen
      onClicked: root.moreOpen = !root.moreOpen
    }
  }

  Repeater {
    model: root.overflow && root.moreOpen ? root.actions.slice(2) : []

    ActionButton {}
  }
}
