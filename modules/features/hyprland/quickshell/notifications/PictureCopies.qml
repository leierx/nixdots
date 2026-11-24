pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// Its own window, moved rather than destroyed as monitors go: an item destroyed mid-grab crashes Qt's render thread.
PanelWindow {
  id: window

  readonly property var wanted: Notifs.entries.reduce((wanted, entry) => [...wanted, ...["image", "appIcon"].filter(role => entry.wants(role)).map(role => ({ key: `${entry.uid}-${role}`, entry, role }))], [])
  // A copy goes only once its grab is back, never with what it copies.
  property var copies: []

  onWantedChanged: {
    const known = new Set(window.copies.map(copy => copy.key));
    const added = window.wanted.filter(copy => !known.has(copy.key));
    if (added.length > 0) window.copies = [...window.copies, ...added];
  }

  function copied(key: string): void {
    window.copies = window.copies.filter(copy => copy.key !== key);
  }

  screen: Screens.real[0] ?? null
  visible: Screens.real.length > 0
  anchors {
    top: true
    left: true
  }
  implicitWidth: 1
  implicitHeight: 1
  exclusiveZone: 0
  color: "transparent"
  mask: Region {}

  // Above fullscreen windows too, or Hyprland stops drawing it and a grab never comes back.
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell:pictures"

  // Drawn left of the window, where nobody sees them, so the saved history keeps them whether they pop up or not.
  Item {
    x: -width
    width: 80
    height: 80

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
}
