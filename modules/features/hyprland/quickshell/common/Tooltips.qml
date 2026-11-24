pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

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
  property point pendingOrigin
  readonly property bool shown: text !== ""

  function request(item: Item, text: string, window: var): void {
    if (owner === item) return;
    // GTK's browse mode: from one tooltip to the next, the next shows at once.
    const browsing = shown || browse.running;
    hide();
    pending = item;
    pendingText = text;
    // Now, while its screen is surely there.
    pendingScreen = window?.screen?.name ?? "";
    pendingOrigin = origin(window);
    delay.interval = browsing ? 0 : 500;
    delay.restart();
  }

  function cancel(item: Item): void {
    if (pending === item) {
      pending = null;
      delay.stop();
    }
    if (owner === item) hide();
  }

  // Where a window sits on its screen, which Qt never says for a layer surface: by its anchors, and below the bar, the one exclusive zone, for one that keeps out of them.
  function origin(window: var): point {
    const screen = window?.screen;
    if (!screen) return Qt.point(0, 0);
    const anchors = window.anchors;
    const x = anchors.left ? 0 : anchors.right ? screen.width - window.width : (screen.width - window.width) / 2;
    const top = window.exclusionMode === ExclusionMode.Normal ? Theme.barHeight : 0;
    const y = anchors.top ? top : anchors.bottom ? screen.height - window.height : (screen.height - window.height) / 2;
    return Qt.point(x, y);
  }

  function hide(): void {
    if (shown) browse.restart();
    owner = null;
    text = "";
  }

  Timer {
    id: browse

    interval: 500
  }

  Timer {
    id: delay

    onTriggered: {
      const item = root.pending;
      root.pending = null;
      if (!item || !item.visible || root.pendingText === "") return;
      const at = item.mapToItem(null, 0, 0);
      root.target = Qt.rect(root.pendingOrigin.x + at.x, root.pendingOrigin.y + at.y, item.width, item.height);
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
      browse.stop();
      root.pending = null;
      delay.stop();
    }
  }
}
