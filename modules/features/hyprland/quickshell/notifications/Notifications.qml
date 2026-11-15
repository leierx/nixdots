import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// The notification daemon's windows: popups in the top right corner and the
// notification center with its calendar, dropping down from the middle of the
// bar. Scripts reach it with `qs ipc -c shell call notifications <function>`.
Scope {
  IpcHandler {
    target: "notifications"

    function toggle(): void {
      Panels.toggle("notifications");
    }

    function open(): void {
      Panels.open("notifications");
    }

    function close(): void {
      if (Panels.active === "notifications") Panels.close();
    }

    function dnd(): bool {
      return Notifs.dnd;
    }

    function count(): int {
      return Notifs.entries.length;
    }

    function toggleDnd(): void {
      Notifs.dnd = !Notifs.dnd;
    }

    function setDnd(on: bool): void {
      Notifs.dnd = on;
    }

    function hidePopups(): void {
      Notifs.hidePopups();
    }

    function clear(): void {
      Notifs.clear();
    }
  }

  NotificationPopups {}

  // Created as it opens, so every group starts collapsed, and unloaded once it
  // has animated closed.
  LazyLoader {
    id: center

    NotificationCenter {
      onHidden: center.active = false
    }
  }

  Connections {
    target: Panels

    function onActiveChanged() {
      if (Panels.active === "notifications") center.active = true;
    }
  }
}
