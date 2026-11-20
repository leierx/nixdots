import QtQuick
import QtQml.Models
import Qt.labs.platform

// `qs-tray NAME COUNT`: COUNT items under the app NAME, each with a short menu.
QtObject {
  id: root

  readonly property var args: Qt.application.arguments.slice(Qt.application.arguments.indexOf("--") + 1)
  readonly property string name: args[0] ?? "tray"

  property Instantiator icons: Instantiator {
    active: false
    model: Number(root.args[1] ?? 1)

    SystemTrayIcon {
      required property int index

      visible: true
      icon.source: Qt.resolvedUrl("icon.svg")
      tooltip: `${root.name} ${index}`

      menu: Menu {
        MenuItem {
          text: `Open ${root.name}`
          onTriggered: console.info(`triggered Open ${root.name}`)
        }
        MenuItem {
          text: "Quit"
          onTriggered: Qt.quit()
        }
      }
    }
  }

  // The item's id is the application's name as it registers.
  Component.onCompleted: {
    Qt.application.name = root.name;
    icons.active = true;
  }
}
