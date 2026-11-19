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
  // Null once the item leaves the tray.
  property SystemTrayItem menuItem: null
  // Its icon, which keeps the menu open while the pointer rests on it.
  property TrayIcon menuIcon: null
  property point menuAnchor
  // A name per screen, so a menu on one monitor closes one open on another; set once, so it outlives the screen.
  property string panel: ""

  visible: icons.count > 0
  implicitWidth: row.implicitWidth + 8
  implicitHeight: 26
  Component.onCompleted: panel = `tray:${screen.name}`
  // Gone with its monitor, the menu would otherwise stay open in Panels.
  Component.onDestruction: if (Panels.active === panel) Panels.close()
  onMenuItemChanged: {
    if (menuItem === null && Panels.active === panel) Panels.close();
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
      onClicked: mouse => {
        const item = icon.modelData;
        const opensMenu = item.hasMenu && (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && item.onlyMenu));
        if (opensMenu && Panels.active === root.panel && root.menuItem === item) {
          Panels.close();
        } else if (opensMenu) {
          // The menu's window and the bar's both start at the screen's corner.
          root.menuAnchor = mapToItem(null, mouse.x, mouse.y);
          root.menuItem = item;
          root.menuIcon = icon;
          Panels.open(root.panel);
        } else {
          Panels.close();
          if (mouse.button === Qt.MiddleButton) item.secondaryActivate();
          else if (mouse.button === Qt.LeftButton && !item.onlyMenu) item.activate();
        }
      }
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
      id: icons

      model: ScriptModel {
        values: SystemTray.items.values.filter(item => item.status !== Status.Passive)
      }

      TrayIcon {}
    }
  }

  // Keyed by item, so switching to another icon's menu starts it afresh.
  Variants {
    model: Panels.active === root.panel && root.menuItem !== null ? [root.menuItem] : []

    TrayMenu {
      required property SystemTrayItem modelData

      screen: root.screen
      name: root.panel
      menu: modelData.menu
      anchor: root.menuAnchor
      held: root.menuIcon?.hovered ?? false
    }
  }
}
