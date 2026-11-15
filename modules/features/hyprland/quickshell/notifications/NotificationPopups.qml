pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// Popups stacked in the top right corner, below the bar, newest on top. Each
// stays on the monitor that was focused when it arrived. Only the cards take
// clicks; the rest of the window passes them through to the windows below.
// The window stays mapped while empty, so the last popup still slides out.
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: window

    required property ShellScreen modelData

    screen: modelData
    anchors {
      top: true
      right: true
      bottom: true
    }
    // GNOME Shell's 34em banners, with room on the left for their shadows.
    implicitWidth: 24 + Math.round(34 * Theme.em) + Theme.gap
    exclusiveZone: 0
    color: "transparent"
    mask: Region {
      item: list.contentItem
    }

    // Above fullscreen windows, where critical notifications still pop up.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"

    ListView {
      id: list

      anchors {
        fill: parent
        margins: Theme.gap
        leftMargin: 24
      }
      spacing: Theme.gap
      interactive: false
      model: ScriptModel {
        values: Notifs.popups.filter(e => e.screen === window.modelData.name)
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

      remove: Transition {
        NumberAnimation {
          property: "x"
          to: list.width
          duration: 200
          easing.type: Easing.InCubic
        }

        NumberAnimation {
          property: "opacity"
          to: 0
          duration: 200
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
