pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.common

Scope {
  id: root

  readonly property bool open: Panels.active === "power"
  property bool firmware: false

  GlobalShortcut {
    name: "power"
    description: "Power menu"
    onPressed: Panels.toggle("power")
  }

  // Firmware setup is a UEFI variable; a BIOS machine has no such restart.
  Process {
    running: true
    command: ["test", "-d", "/sys/firmware/efi"]
    onExited: code => root.firmware = code === 0
  }

  LazyLoader {
    active: root.open

    PowerMenu {
      firmware: root.firmware
    }
  }
}
