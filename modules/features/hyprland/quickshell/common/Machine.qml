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
  property real seconds: -1
  readonly property string uptime: {
    if (seconds < 0) return "";
    const minutes = Math.floor(seconds / 60);
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

  FileView {
    path: "/proc/sys/kernel/hostname"
    onLoaded: root.hostname = text().trim()
  }

  FileView {
    id: up

    path: "/proc/uptime"
    onLoaded: {
      const seconds = parseFloat(text());
      if (seconds >= 0) root.seconds = seconds;
    }
  }

  // Read again each minute, rather than counted from the wall clock, which can be set or stepped under it.
  Connections {
    target: Time

    function onNowChanged(): void {
      up.reload();
    }
  }
}
