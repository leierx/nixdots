pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common

// The status notifier items, apps' tray icons, leaving out the passive ones
// that ask to be hidden. Left click activates an item, middle click is its
// secondary action, right click opens its menu below it; an item that is only
// a menu opens it on left click too.
Row {
  id: root

  required property ShellScreen screen
  // Each icon's square, as tall as the bar.
  required property int size

  // The item whose menu is open; null once it leaves the tray.
  property SystemTrayItem menuItem: null
  property point menuAnchor
  // A name per screen, so a menu on one monitor closes one open on another.
  readonly property string panel: `tray:${screen?.name}`

  onMenuItemChanged: {
    if (menuItem === null && Panels.active === panel) Panels.close();
  }

  Repeater {
    model: ScriptModel {
      values: SystemTray.items.values.filter(item => item.status !== Status.Passive)
    }

    // Just the icon, like the NixOS logo: no hover or pressed state.
    MouseArea {
      id: button

      required property SystemTrayItem modelData

      implicitWidth: root.size
      implicitHeight: root.size
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
      onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) {
          modelData.secondaryActivate();
        } else if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
          modelData.activate();
        } else if (modelData.hasMenu) {
          root.menuAnchor = mapToItem(null, width / 2, height);
          root.menuItem = modelData;
          Panels.open(root.panel);
        }
      }

      IconImage {
        anchors.centerIn: parent
        implicitSize: 18
        source: button.modelData.icon
        // Apps that send pixels get a new source on every change; keep the old one up meanwhile.
        backer.retainWhileLoading: true
      }
    }
  }

  LazyLoader {
    active: Panels.active === root.panel && root.menuItem !== null

    TrayMenu {
      screen: root.screen
      menu: root.menuItem.menu
      anchor: root.menuAnchor
    }
  }
}
