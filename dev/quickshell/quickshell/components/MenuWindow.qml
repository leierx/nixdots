import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The frame every menu shares: a transparent surface over the whole monitor,
// with a card for the menu's widgets. Escape or a click outside the card
// closes the menu.
//
// No screen is set, so Hyprland opens it on the focused monitor. Hyprland's
// layer rule for the "quickshell:menu" namespace dims everything behind it and
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
  WlrLayershell.namespace: "quickshell:menu"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  // Everywhere outside the card.
  MouseArea {
    anchors.fill: parent
    onClicked: MenuState.close()
  }

  Rectangle {
    id: card

    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round((parent.height - root.fullHeight) / 2) - Theme.cardPadding
    width: Theme.cardWidth
    height: body.implicitHeight + Theme.cardPadding * 2
    radius: Theme.cardRadius
    color: Theme.bg
    border.width: 1
    border.color: Theme.border

    // Keys the search field does not use travel up to here.
    Keys.onEscapePressed: MenuState.close()

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
        margins: Theme.cardPadding
      }
    }
  }
}
