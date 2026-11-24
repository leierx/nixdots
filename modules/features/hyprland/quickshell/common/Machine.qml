pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // As os-release names it (NixOS nix-snowflake, Debian debian-logo), through the icon theme.
  property string logo: ""
  readonly property string icon: logo === "" ? "" : Quickshell.iconPath(logo, "distributor-logo")
  property string hostname: ""
  property real booted: 0
  readonly property string uptime: {
    if (booted === 0) return "";
    const minutes = Math.max(0, Math.floor((Time.now.getTime() - booted) / 60000));
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    if (days > 0) return days === 1 ? "Up 1 day" : `Up ${days} days`;
    if (hours > 0) return `Up ${Theme.unit(hours, "h")} ${Theme.unit(minutes % 60, "min")}`;
    return `Up ${Theme.unit(minutes, "min")}`;
  }

  FileView {
    path: "/etc/os-release"
    blockLoading: true
    onLoaded: root.logo = /^LOGO=["']?([^"'\n]+)/m.exec(text())?.[1] ?? "distributor-logo"
  }

  Process {
    running: true
    command: ["cat", "/proc/sys/kernel/hostname", "/proc/uptime"]
    stdout: StdioCollector {
      onStreamFinished: {
        const [name, up] = text.split("\n");
        root.hostname = (name ?? "").trim();
        const seconds = parseFloat(up ?? "");
        if (seconds >= 0) root.booted = Date.now() - seconds * 1000;
      }
    }
  }
}
