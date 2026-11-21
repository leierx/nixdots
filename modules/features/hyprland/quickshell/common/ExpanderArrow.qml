import QtQuick
import qs.nix

// Adwaita's pan-down, turned to point as it says: the one chevron.
Glyph {
  id: root

  property string pointing: "down"

  path: Symbols.panDown
  rotation: ({ down: 0, left: 90, up: 180, right: -90 })[pointing] ?? 0

  Behavior on rotation {
    NumberAnimation {
      duration: Theme.popupTime
      easing.type: Easing.OutQuad
    }
  }
}
