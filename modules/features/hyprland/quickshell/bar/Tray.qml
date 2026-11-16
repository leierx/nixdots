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
  property Item menuButton: null
  property point menuAnchor
  // A name per screen, so a menu on one monitor closes one open on another.
  readonly property string panel: `tray:${screen?.name}`

  leftPadding: 7
  rightPadding: 7

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
      menu: modelData.menu
      anchor: root.menuAnchor
      held: root.menuButton?.containsMouse ?? false
    }
  }
}
