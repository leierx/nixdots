pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.common

Scope {
  id: root

  readonly property bool open: Panels.active === "power"
  readonly property string host: hostFile.text().trim()
  property bool firmware: false
  property real uptime: 0

  onOpenChanged: {
    if (!open) return;
    uptimeFile.reload();
    root.uptime = parseFloat(uptimeFile.text()) || 0;
  }

  GlobalShortcut {
    name: "power"
    description: "Power menu"
    onPressed: Panels.toggle("power")
  }

  FileView {
    id: hostFile

    path: "/proc/sys/kernel/hostname"
    blockLoading: true
  }

  FileView {
    id: uptimeFile

    path: "/proc/uptime"
    blockLoading: true
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
      host: root.host
      uptime: root.uptime
      firmware: root.firmware
    }
  }
}
