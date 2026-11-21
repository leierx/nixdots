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
    // GNOME Shell's 34 em banners, with room on the left for their shadows.
    implicitWidth: shadowRoom + Math.round(34 * Theme.em) + Theme.rise
    exclusiveZone: 0
    color: "transparent"
    // Stays mapped while empty, so the last popup still slides out.
    mask: Region {
      regions: window.cards.filter(card => card.visible).map(card => card.region)
    }

    // Above fullscreen windows, where critical notifications still pop up.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"

    // Pictures only the server holds, drawn once each left of the first screen's window, where nobody sees them, so the saved history keeps them whether they pop up or not.
    readonly property bool copying: window.screenName !== "" && window.screenName === Screens.real[0]?.name
    readonly property var wanted: !copying ? [] : Notifs.entries.reduce((wanted, entry) => [...wanted, ...["image", "appIcon"].filter(role => entry.wants(role)).map(role => ({ key: `${entry.uid}-${role}`, entry, role }))], [])
    // A copy goes only once its grab is back, never with what it copies: an item destroyed mid-grab crashes Qt's render thread.
    property var copies: []

    onWantedChanged: {
      const known = new Set(window.copies.map(copy => copy.key));
      const added = window.wanted.filter(copy => !known.has(copy.key));
      if (added.length > 0) window.copies = [...window.copies, ...added];
    }

    function copied(key: string): void {
      window.copies = window.copies.filter(copy => copy.key !== key);
    }

    Item {
      x: -width
      width: 80
      height: 80
      visible: window.copying

      Repeater {
        model: ScriptModel {
          objectProp: "key"
          values: window.copies
        }

        Image {
          id: copy

          required property var modelData
          readonly property int size: modelData.role === "image" ? 80 : 28
          property int grabbing: 0

          function settle(): void {
            if (copy.grabbing === 0 && !(copy.modelData.entry?.wants(copy.modelData.role) && copy.status === Image.Loading)) window.copied(copy.modelData.key);
          }

          width: size
          height: size
          sourceSize: Qt.size(size, size)
          // Null once its notification is dismissed.
          source: modelData.entry ? modelData.entry.source(modelData.role) : ""
          fillMode: modelData.role === "image" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
          // The image provider reuses URLs for different notifications.
          cache: false
          onStatusChanged: {
            if (status === Image.Loading) return;
            if (status !== Image.Ready || !modelData.entry?.wants(modelData.role)) {
              copy.settle();
              return;
            }
            copy.grabbing++;
            const from = copy.source;
            copy.grabToImage(result => {
              // Kept only if it is still the picture the notification shows.
              if (copy.source === from) copy.modelData.entry?.keep(copy.modelData.role, result);
              copy.grabbing--;
              copy.settle();
            }, Qt.size(copy.sourceSize.width, copy.sourceSize.height));
          }
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
