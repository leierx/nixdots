pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common

// A module on the bar rather than buttons: few tray icons do anything on a left click.
Item {
  id: root

  required property ShellScreen screen
  // What the bar leaves it before the clock.
  property real room: 1e9
  // Null once the item leaves the tray.
  property SystemTrayItem menuItem: null
  // The icon or overflow cell it opened from, which keeps the menu open while the pointer rests on it.
  property var menuIcon: null
  property point menuAnchor
  // Names per screen, so a menu on one monitor closes one open on another; set once, so they outlive the screen.
  property string panel: ""
  property string overflowPanel: ""
  property real overflowX: 0

  // In the order they came, so the first keep their places on the bar.
  readonly property var items: TrayOrder.items.filter(item => item.status !== Status.Passive)
  readonly property bool crowded: items.length * 26 + 8 > room
  // The rule and the button.
  readonly property real reserve: rule.width + more.implicitWidth
  // Four beside the button, fewer only where even that would reach the clock.
  readonly property int kept: crowded ? Math.max(0, Math.min(4, Math.floor((room - 8 - reserve) / 26))) : items.length
  readonly property var shown: items.slice(0, kept)
  readonly property var hidden: items.slice(kept)
  visible: items.length > 0
  implicitWidth: row.implicitWidth + 8
  implicitHeight: 26
  Component.onCompleted: {
    panel = `tray:${screen.name}`;
    overflowPanel = `tray-overflow:${screen.name}`;
  }
  // Gone with its monitor, the menu would otherwise stay open in Panels.
  Component.onDestruction: if (Panels.active === panel || Panels.active === overflowPanel) Panels.close()
  onMenuItemChanged: {
    if (menuItem === null && Panels.active === panel) Panels.close();
  }
  onHiddenChanged: {
    if (hidden.length === 0 && Panels.active === overflowPanel) Panels.close();
  }

  // A click on an icon, on the bar or in the overflow, whose menu then opens over it.
  function press(item: SystemTrayItem, icon: Item, button: int, x: real, y: real, overflow: bool): void {
    const opensMenu = item.hasMenu && (button === Qt.RightButton || (button === Qt.LeftButton && item.onlyMenu));
    const open = Panels.active === (overflow ? root.overflowPanel : root.panel) && root.menuItem === item;
    if (opensMenu && open) {
      if (overflow) root.menuItem = null;
      else Panels.close();
    } else if (opensMenu) {
      // Every window here starts at the screen's corner.
      root.menuAnchor = icon.mapToItem(null, x, y);
      root.menuIcon = icon;
      root.menuItem = item;
      if (!overflow) Panels.open(root.panel);
    } else {
      Panels.close();
      if (button === Qt.MiddleButton) item.secondaryActivate();
      else if (button === Qt.LeftButton && !item.onlyMenu) item.activate();
    }
  }

  component TrayIcon: Item {
    id: icon

    required property SystemTrayItem modelData
    readonly property bool hovered: area.containsMouse

    implicitWidth: 26
    implicitHeight: 26

    MouseArea {
      id: area

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.ArrowCursor
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
      onClicked: mouse => root.press(icon.modelData, icon, mouse.button, mouse.x, mouse.y, false)
    }

    IconImage {
      anchors.centerIn: parent
      implicitSize: 18
      source: icon.modelData.icon
      // Apps that send pixels get a new source on every change; keep the old one up meanwhile.
      backer.retainWhileLoading: true
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: Theme.button
  }

  Row {
    id: row

    anchors.centerIn: parent

    Repeater {
      model: ScriptModel {
        values: root.shown
      }

      TrayIcon {}
    }

    Item {
      id: rule

      visible: more.visible
      width: 9
      height: 26

      Rectangle {
        anchors.centerIn: parent
        width: 1
        height: 14
        color: Theme.border
      }
    }

    // Closes the pill, so the tray stays one shape.
    BarButton {
      id: more

      visible: root.hidden.length > 0
      expander: true
      checked: Panels.active === root.overflowPanel
      onClicked: {
        root.menuItem = null;
        root.overflowX = more.mapToItem(null, more.width / 2, 0).x;
        Panels.toggle(root.overflowPanel);
      }
    }
  }

  LazyLoader {
    active: Panels.active === root.overflowPanel

    TrayOverflow {
      screen: root.screen
      name: root.overflowPanel
      anchorX: root.overflowX
      top: root.Window.height
      items: root.hidden
      onPressed: (item, cell, button, x, y) => root.press(item, cell, button, x, y, true)
    }
  }

  // Keyed by item, so switching to another icon's menu starts it afresh.
  Variants {
    model: Panels.active === root.panel && root.menuItem !== null ? [root.menuItem] : []

    TrayMenu {
      required property SystemTrayItem modelData

      screen: root.screen
      name: root.panel
      // Null for a moment once its item has gone.
      menu: modelData?.menu ?? null
      anchor: root.menuAnchor
      held: root.menuIcon?.hovered ?? false
      onDismissed: if (Panels.active === root.panel) Panels.close()
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
