pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

Variants {
  model: Quickshell.screens

  PanelWindow {
    id: window

    required property ShellScreen modelData
    // Takes the popups of a monitor that has gone.
    readonly property bool fallback: modelData === Quickshell.screens[0]
    readonly property int shadowRoom: 24
    // Cards register here, as the window's input region is theirs alone: a click between them reaches the window behind.
    property list<Item> cards: []

    screen: modelData
    anchors {
      top: true
      right: true
      bottom: true
    }
    // Narrower than GNOME Shell's 34em banners, with room on the left for their shadows.
    implicitWidth: shadowRoom + Math.round(30 * Theme.em) + Theme.gap
    exclusiveZone: 0
    color: "transparent"
    // Stays mapped while empty, so the last popup still slides out.
    mask: Region {
      regions: window.cards.filter(card => card.visible).map(card => card.region)
    }

    // Above fullscreen windows, where critical notifications still pop up.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"

    ListView {
      id: list

      anchors {
        fill: parent
        margins: Theme.gap
        leftMargin: window.shadowRoom
      }
      spacing: Theme.gap
      interactive: false
      model: ScriptModel {
        values: Notifs.popups.filter(e => e.screen === window.modelData?.name || (window.fallback && !Quickshell.screens.some(s => s.name === e.screen)))
      }

      delegate: NotificationCard {
        id: card

        required property NotifEntry modelData
        required property int index
        // One past the screen's edge could not be clicked, so it waits, out of sight, for room.
        readonly property bool fits: index === 0 || y + height <= ListView.view.height
        readonly property Region region: Region {
          item: card
        }

        width: ListView.view.width
        visible: fits
        entry: modelData

        Component.onCompleted: window.cards = [...window.cards, card]
        Component.onDestruction: window.cards = window.cards.filter(other => other !== card)

        Binding {
          target: card.modelData
          property: "waiting"
          value: !card.fits
        }
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
