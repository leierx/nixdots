pragma Singleton

import QtQuick
import Quickshell

// The one tooltip on screen: what it says, on which screen and under what, shown once the pointer has rested half a second, as GTK's.
Singleton {
  id: root

  property string text: ""
  property string screen: ""
  // In its window's coordinates, which are its screen's: tooltips live on the bar and in panels, both from the screen's corner.
  property rect target: Qt.rect(0, 0, 0, 0)
  property Item owner: null
  property Item pending: null
  property string pendingText: ""
  property string pendingScreen: ""
  readonly property bool shown: text !== ""

  function request(item: Item, text: string, screen: string): void {
    if (owner === item) return;
    hide();
    pending = item;
    pendingText = text;
    pendingScreen = screen;
    delay.restart();
  }

  function cancel(item: Item): void {
    if (pending === item) {
      pending = null;
      delay.stop();
    }
    if (owner === item) hide();
  }

  function hide(): void {
    owner = null;
    text = "";
  }

  Timer {
    id: delay

    interval: 500
    onTriggered: {
      const item = root.pending;
      root.pending = null;
      if (!item || !item.visible || root.pendingText === "") return;
      const at = item.mapToItem(null, 0, 0);
      root.target = Qt.rect(at.x, at.y, item.width, item.height);
      root.screen = root.pendingScreen;
      root.owner = item;
      root.text = root.pendingText;
    }
  }

  // A panel opening or closing moves everything under the pointer.
  Connections {
    target: Panels

    function onActiveChanged(): void {
      root.hide();
      root.pending = null;
      delay.stop();
    }
  }
}
