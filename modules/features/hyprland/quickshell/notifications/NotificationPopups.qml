pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// Popups stacked in the top right corner, below the bar, newest on top. Each
// stays on the monitor that was focused when it arrived. Only the cards take
// clicks; the rest of the column passes them through to the windows below.
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: window

    required property ShellScreen modelData
    readonly property var popups: Notifs.popups.filter(e => e.screen === modelData.name)

    screen: modelData
    visible: popups.length > 0
    anchors {
      top: true
      right: true
      bottom: true
    }
    implicitWidth: Theme.notificationWidth + Theme.notificationGap * 2
    exclusiveZone: 0
    color: "transparent"
    mask: Region {
      item: list.contentItem
    }

    WlrLayershell.namespace: "quickshell:notifications"

    ListView {
      id: list

      anchors {
        fill: parent
        margins: Theme.notificationGap
      }
      spacing: Theme.notificationGap
      interactive: false
      model: ScriptModel {
        values: window.popups
      }

      delegate: NotificationCard {
        required property NotifEntry modelData

        width: ListView.view.width
        entry: modelData
      }

      add: Transition {
        NumberAnimation {
          property: "x"
          from: list.width
          duration: 200
          easing.type: Easing.OutCubic
        }
      }

      displaced: Transition {
        NumberAnimation {
          property: "y"
          duration: 200
          easing.type: Easing.OutCubic
        }
      }
    }
  }
}
