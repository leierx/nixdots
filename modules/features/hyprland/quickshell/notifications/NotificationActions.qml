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

  // Shell's %notification_button: the foreground at 15 %, 30 % under the pointer, 20 % pressed.
  component ActionButton: Button {
    required property NotificationAction modelData

    objectName: "action:" + (modelData?.text ?? "")
    color: pressed ? Theme.messageButtonActiveBg : hovered ? Theme.messageButtonHoverBg : Theme.messageButtonBg
    Layout.fillWidth: true
    // Equal shares, whatever their labels.
    Layout.preferredWidth: 1
    text: modelData?.text ?? ""
    onClicked: if (modelData) root.invoked(modelData)
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Theme.basePadding

    Repeater {
      model: root.overflow ? root.actions.slice(0, 2) : root.actions

      ActionButton {}
    }

    Button {
      Layout.fillWidth: true
      Layout.preferredWidth: 1
      visible: root.overflow
      color: pressed ? Theme.messageButtonActiveBg : hovered ? Theme.messageButtonHoverBg : Theme.messageButtonBg
      objectName: "action:More"
      text: "More"
      expander: true
      pointing: root.moreOpen ? "up" : "down"
      onClicked: root.moreOpen = !root.moreOpen
    }
  }

  Repeater {
    model: root.overflow && root.moreOpen ? root.actions.slice(2) : []

    ActionButton {}
  }
}
