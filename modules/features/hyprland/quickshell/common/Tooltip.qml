import QtQuick
import Quickshell
import Quickshell.Wayland

// A card under a bar item while the pointer rests on it. A layer of its own on the bar's screen, as a
// PopupWindow lands off by the monitor's x times QT_SCALE_FACTOR - 1.
PanelWindow {
  id: root

  required property Item anchorItem
  property bool shown: false
  // Whether it has anything to say.
  property bool available: true
  // The item's middle, in the bar's and so the screen's coordinates, taken as it opens.
  property real anchorX: 0
  // A pass over the bar on the way elsewhere opens nothing.
  property bool settled: false
  default property alias content: body.data

  onShownChanged: {
    if (shown) {
      anchorX = anchorItem.mapToItem(null, anchorItem.width / 2, 0).x;
      delay.restart();
    } else {
      delay.stop();
      settled = false;
    }
  }

  anchors {
    top: true
    left: true
    right: true
  }
  // Below the bar, over windows.
  exclusiveZone: 0
  visible: shown && settled && available
  implicitHeight: card.implicitHeight + 48
  color: "transparent"
  // Nothing in it takes a click.
  mask: Region {}

  WlrLayershell.namespace: "quickshell:tooltip"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Timer {
    id: delay

    interval: 250
    onTriggered: root.settled = true
  }

  Card {
    id: card

    // Centred under the item, and kept on the screen.
    x: Math.max(Theme.gap, Math.min(root.width - width - Theme.gap, root.anchorX - width / 2))
    y: 6
    width: implicitWidth
    height: implicitHeight
    implicitWidth: body.childrenRect.width + 2 * Theme.padding
    implicitHeight: body.childrenRect.height + 2 * Theme.padding
    radius: Theme.cardRadius

    Item {
      id: body

      x: Theme.padding
      y: Theme.padding
    }
  }
}
