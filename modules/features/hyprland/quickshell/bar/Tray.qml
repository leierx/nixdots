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
  property Button menuButton: null
  property point menuAnchor
  // A name per screen, so a menu on one monitor closes one open on another; set once, so it outlives the screen.
  property string panel: ""

  visible: icons.count > 0

  Component.onCompleted: panel = `tray:${screen.name}`
  // Gone with its monitor, the menu would otherwise stay open in Panels.
  Component.onDestruction: if (Panels.active === panel) Panels.close()

  onMenuItemChanged: {
    if (menuItem === null && Panels.active === panel) Panels.close();
  }

  Repeater {
    id: icons

    model: ScriptModel {
      values: SystemTray.items.values.filter(item => item.status !== Status.Passive)
    }

    BarButton {
      id: icon

      required property SystemTrayItem modelData

      acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
      onClicked: button => {
        const opensMenu = modelData.hasMenu && (button === Qt.RightButton || (button === Qt.LeftButton && modelData.onlyMenu));
        if (opensMenu && Panels.active === root.panel && root.menuItem === modelData) {
          Panels.close();
        } else if (opensMenu) {
          // The menu's window and the bar's both start at the screen's corner.
          root.menuAnchor = mapToItem(null, pointer.point.position.x, pointer.point.position.y);
          root.menuItem = modelData;
          root.menuButton = icon;
          Panels.open(root.panel);
        } else {
          Panels.close();
          if (button === Qt.MiddleButton) modelData.secondaryActivate();
          else if (button === Qt.LeftButton && !modelData.onlyMenu) modelData.activate();
        }
      }

      // Where the menu opens, as a click carries no position.
      HoverHandler {
        id: pointer
      }

      IconImage {
        anchors.centerIn: parent
        implicitSize: 18
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
      held: root.menuButton?.hovered ?? false
    }
  }
}
