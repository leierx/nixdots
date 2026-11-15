import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// The frame every menu shares: a transparent surface over the whole monitor,
// with a card for the menu's widgets. Escape or a click outside the card
// closes the menu.
//
// No screen is set, so Hyprland opens it on the focused monitor. Hyprland's
// layer rule for the "quickshell:launcher" namespace dims everything behind it and
// turns its animations off.
//
//   MenuWindow {
//     fullHeight: list.fullHeight
//
//     MenuList {
//       id: list
//     }
//   }
PanelWindow {
  id: root

  // The content's height when it is at its tallest. The card's top edge sits
  // where content this tall would be centred, so when a search shortens the
  // list only the bottom edge moves and the search field stays put.
  property real fullHeight: body.implicitHeight

  property int cardWidth: Theme.px(640)

  // The menu's widgets, stacked top to bottom inside the card.
  default property alias content: body.data

  color: "transparent"
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  // Cover the bar rather than being pushed aside by it.
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell:launcher"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  // Everywhere outside the card.
  MouseArea {
    anchors.fill: parent
    onClicked: Panels.close()
  }

  Rectangle {
    id: card

    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round((parent.height - root.fullHeight) / 2) - Theme.padding
    width: root.cardWidth
    height: body.implicitHeight + Theme.padding * 2
    radius: Theme.radius
    color: Theme.bg
    border.width: 1
    border.color: Theme.border

    // Keys the search field does not use travel up to here.
    Keys.onEscapePressed: Panels.close()

    // Keeps clicks on the card's padding from closing the menu.
    MouseArea {
      anchors.fill: parent
    }

    Column {
      id: body

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: Theme.padding
      }
    }
  }
}
