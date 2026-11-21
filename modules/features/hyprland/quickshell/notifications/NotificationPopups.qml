pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

Variants {
  model: Screens.real

  PanelWindow {
    id: window

    required property ShellScreen modelData
    // Taken once: the screen object dangles while its monitor goes.
    property string screenName: ""
    readonly property int shadowRoom: 24
    // Cards register here, as the window's input region is theirs alone: a click between them reaches the window behind.
    property list<Item> cards: []

    Component.onCompleted: screenName = modelData?.name ?? ""
    screen: modelData
    anchors {
      top: true
      right: true
      bottom: true
    }
    // Narrower than GNOME Shell's 34em banners, with room on the left for their shadows.
    implicitWidth: shadowRoom + Math.round(30 * Theme.em) + Theme.rise
    exclusiveZone: 0
    color: "transparent"
    // Stays mapped while empty, so the last popup still slides out.
    mask: Region {
      regions: window.cards.filter(card => card.visible).map(card => card.region)
    }

    // Above fullscreen windows, where critical notifications still pop up.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"

    // Pictures only the server holds, drawn once each left of the window, where nobody sees them, so the saved history keeps them whether they pop up or not.
    Item {
      x: -width
      width: 80
      height: 80
      visible: window.screenName !== "" && window.screenName === Screens.real[0]?.name

      Repeater {
        model: ScriptModel {
          objectProp: "key"
          values: Notifs.entries.reduce((wanted, entry) => [...wanted, ...["image", "appIcon"].filter(role => entry.wants(role)).map(role => ({ key: `${entry.uid}-${role}`, entry, role }))], [])
        }

        Image {
          id: copy

          required property var modelData
          readonly property int size: modelData.role === "image" ? 80 : 28

          width: size
          height: size
          sourceSize: Qt.size(size, size)
          source: modelData.entry.source(modelData.role)
          fillMode: modelData.role === "image" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
          // The image provider reuses URLs for different notifications.
          cache: false
          onStatusChanged: if (status === Image.Ready) modelData.entry.keep(modelData.role, copy)
        }
      }
    }

    ListView {
      id: list

      anchors {
        fill: parent
        margins: Theme.rise
        leftMargin: window.shadowRoom
      }
      spacing: Theme.padding
      interactive: false
      model: ScriptModel {
        values: Notifs.popups.filter(e => e.screen === window.screenName)
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

        // Shell's banner arriving: a fade and a growth from 90 %, easing back past its size; its own, as a ListView transition cut short by the next arrival leaves its item where it stopped.
        opacity: 0
        scale: 0.9
        Component.onCompleted: {
          window.cards = [...window.cards, card];
          arrive.start();
        }

        ParallelAnimation {
          id: arrive

          NumberAnimation {
            target: card
            property: "opacity"
            to: 1
            duration: Theme.bannerTime
            easing.type: Easing.OutQuad
          }

          NumberAnimation {
            target: card
            property: "scale"
            to: 1
            duration: Theme.bannerTime
            easing.type: Easing.OutBack
          }
        }
        Component.onDestruction: window.cards = window.cards.filter(other => other !== card)

        Binding {
          target: card.modelData
          property: "waiting"
          value: !card.fits
        }
      }


      remove: Transition {
        NumberAnimation {
          property: "x"
          to: list.width
          duration: Theme.bannerTime
          easing.type: Easing.InQuad
        }

        NumberAnimation {
          property: "opacity"
          to: 0
          duration: Theme.bannerTime
        }
      }

      displaced: Transition {
        NumberAnimation {
          property: "y"
          duration: Theme.popupTime
          easing.type: Easing.OutQuad
        }
      }
    }
  }
}
