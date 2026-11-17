pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common

Row {
  id: root

  required property ShellScreen screen

  // Null once the item leaves the tray.
  property SystemTrayItem menuItem: null
  // Its icon, which keeps the menu open while the pointer rests on it.
  property MouseArea menuButton: null
  property point menuAnchor
  // A name per screen, so a menu on one monitor closes one open on another; set once, so it outlives the screen.
  property string panel: ""

  leftPadding: 7
  rightPadding: 7

  Component.onCompleted: panel = `tray:${screen.name}`
  // Gone with its monitor, the menu would otherwise stay open in Panels.
  Component.onDestruction: if (Panels.active === panel) Panels.close()

  onMenuItemChanged: {
    if (menuItem === null && Panels.active === panel) Panels.close();
  }

  Repeater {
    model: ScriptModel {
      values: SystemTray.items.values.filter(item => item.status !== Status.Passive)
    }

    MouseArea {
      id: icon

      required property SystemTrayItem modelData

      implicitWidth: 21
      implicitHeight: 26
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
      hoverEnabled: true
      onClicked: mouse => {
        const opensMenu = modelData.hasMenu && (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && modelData.onlyMenu));
        if (opensMenu && Panels.active === root.panel && root.menuItem === modelData) {
          Panels.close();
        } else if (opensMenu) {
          // The menu's window and the bar's both start at the screen's corner.
          root.menuAnchor = mapToItem(null, mouse.x, mouse.y);
          root.menuItem = modelData;
          root.menuButton = icon;
          Panels.open(root.panel);
        } else {
          Panels.close();
          if (mouse.button === Qt.MiddleButton) modelData.secondaryActivate();
          else if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) modelData.activate();
        }
      }

      IconImage {
        anchors.centerIn: parent
        implicitSize: 17
        source: icon.modelData.icon
        // Apps that send pixels get a new source on every change; keep the old one up meanwhile.
        backer.retainWhileLoading: true
      }
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
      held: root.menuButton?.containsMouse ?? false
    }
  }
}
