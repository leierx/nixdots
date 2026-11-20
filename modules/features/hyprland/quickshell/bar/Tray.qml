pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.common

// Folded behind one chevron, as Windows does: few tray icons are worth the bar's room.
Item {
  id: root

  required property ShellScreen screen
  // Null once the item leaves the tray.
  property SystemTrayItem menuItem: null
  // The overflow cell it opened from, which keeps the menu open while the pointer rests on it.
  property var menuIcon: null
  property point menuAnchor
  // A name per screen, so a menu on one monitor closes one open on another; set once, so it outlives the screen.
  property string overflowPanel: ""
  property real overflowX: 0

  // In the order they came.
  readonly property var items: TrayOrder.items.filter(item => item.status !== Status.Passive)
  visible: items.length > 0
  implicitWidth: more.implicitWidth
  implicitHeight: 26
  Component.onCompleted: {
    overflowPanel = `tray-overflow:${screen.name}`;
  }
  // Gone with its monitor, the menu would otherwise stay open in Panels.
  Component.onDestruction: if (Panels.active === overflowPanel) Panels.close()
  onItemsChanged: {
    if (items.length === 0 && Panels.active === overflowPanel) Panels.close();
  }

  // A click on an icon in the overflow, whose menu then opens over it.
  function press(item: SystemTrayItem, icon: Item, button: int, x: real, y: real): void {
    const opensMenu = item.hasMenu && (button === Qt.RightButton || (button === Qt.LeftButton && item.onlyMenu));
    if (opensMenu && root.menuItem === item) {
      root.menuItem = null;
    } else if (opensMenu) {
      // Every window here starts at the screen's corner.
      root.menuAnchor = icon.mapToItem(null, x, y);
      root.menuIcon = icon;
      root.menuItem = item;
    } else {
      Panels.close();
      if (button === Qt.MiddleButton) item.secondaryActivate();
      else if (button === Qt.LeftButton && !item.onlyMenu) item.activate();
    }
  }

  BarButton {
    id: more

    expander: true
    checked: Panels.active === root.overflowPanel
    onClicked: {
      root.menuItem = null;
      root.overflowX = more.mapToItem(null, more.width / 2, 0).x;
      Panels.toggle(root.overflowPanel);
    }
  }

  LazyLoader {
    active: Panels.active === root.overflowPanel

    TrayOverflow {
      screen: root.screen
      name: root.overflowPanel
      anchorX: root.overflowX
      top: root.Window.height
      items: root.items
      onPressed: (item, cell, button, x, y) => root.press(item, cell, button, x, y)
    }
  }

  // Over the overflow, which stays open beneath it.
  Variants {
    model: Panels.active === root.overflowPanel && root.menuItem !== null ? [root.menuItem] : []

    TrayMenu {
      required property SystemTrayItem modelData

      screen: root.screen
      name: root.overflowPanel
      // Null for a moment once its item has gone.
      menu: modelData?.menu ?? null
      anchor: root.menuAnchor
      held: root.menuIcon?.hovered ?? false
      onDismissed: root.menuItem = null
    }
  }
}
