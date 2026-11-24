pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.common

Scope {
  id: root

  property bool firmware: false

  GlobalShortcut {
    name: "power"
    description: "Power menu"
    onPressed: Panels.toggle("power")
  }

  // logind knows whether the firmware takes a reboot into its setup; a UEFI directory alone does not.
  Process {
    running: true
    command: ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "CanRebootToFirmwareSetup"]
    stdout: StdioCollector {
      onStreamFinished: root.firmware = /"(yes|challenge)"/.test(text)
    }
  }

  // Out here, as the menu goes with its panel while the command still runs.
  Component {
    id: action

    Command {
      running: true
      onDone: destroy()
      onFailed: destroy()
    }
  }

  // Unloaded once it has faded out.
  LazyLoader {
    id: loader

    PowerMenu {
      firmware: root.firmware
      onChosen: command => action.createObject(root, { command })
      onHidden: loader.active = false
    }
  }

  Connections {
    target: Panels

    function onActiveChanged() {
      if (Panels.active === "power") loader.active = true;
    }
  }
}
