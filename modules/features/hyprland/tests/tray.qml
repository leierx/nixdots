import QtQuick
import QtQml.Models
import Qt.labs.platform

QtObject {
  id: root

  property int generation: 0
  property bool rebuilding: false
  // a new list each time, so the menu gets new entries with new ids, as nm-applet's does
  readonly property list<string> networks: [`Network ${generation}`, "Home"]

  property Timer rebuild: Timer {
    interval: 1000
    repeat: true
    running: root.rebuilding
    onTriggered: root.generation++
  }

  property SystemTrayIcon icon: SystemTrayIcon {
    visible: true
    icon.source: Qt.resolvedUrl("icon.svg")
    tooltip: "qs-test tray"
    onActivated: reason => console.info(`activated ${reason}`)

    menu: Menu {
      MenuItem {
        text: "First item"
        onTriggered: console.info("triggered First item")
      }
      MenuItem {
        text: "A label long enough to widen the menu past its usual size"
        onTriggered: console.info("triggered long label")
      }
      MenuItem {
        text: "Checkable"
        checkable: true
        onTriggered: console.info(`triggered Checkable ${checked}`)
      }
      MenuItem {
        text: "Checked"
        checkable: true
        checked: true
        onTriggered: console.info(`triggered Checked ${checked}`)
      }
      MenuItem {
        text: "Disabled"
        enabled: false
      }
      MenuItem {
        text: "With an icon"
        icon.source: Qt.resolvedUrl("icon.svg")
        onTriggered: console.info("triggered With an icon")
      }
      MenuSeparator {}
      MenuItemGroup {
        id: speeds
        exclusive: true
      }
      MenuItem {
        text: "Fast"
        checkable: true
        checked: true
        group: speeds
        onTriggered: console.info("triggered Fast")
      }
      MenuItem {
        text: "Slow"
        checkable: true
        group: speeds
        onTriggered: console.info("triggered Slow")
      }
      MenuSeparator {}
      Menu {
        id: networks
        title: "Networks"

        Instantiator {
          model: root.networks
          delegate: MenuItem {
            required property string modelData
            text: modelData
            onTriggered: console.info(`triggered ${text}`)
          }
          onObjectAdded: (index, item) => networks.insertItem(index, item)
          onObjectRemoved: (index, item) => networks.removeItem(item)
        }
        Menu {
          title: "More networks"

          MenuItem {
            text: "Cafe"
            onTriggered: console.info("triggered Cafe")
          }
          MenuItem {
            text: "Library"
            onTriggered: console.info("triggered Library")
          }
        }
      }
      Menu {
        title: "Settings"

        MenuItem {
          text: "Rebuild every second"
          checkable: true
          checked: root.rebuilding
          onTriggered: {
            root.rebuilding = checked;
            console.info(`triggered rebuild ${checked}`);
          }
        }
      }
      MenuSeparator {}
      MenuItem {
        text: "Quit"
        onTriggered: Qt.quit()
      }
    }
  }
}
