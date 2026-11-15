import Quickshell
import Quickshell.Io

// The notification daemon's popups, in the top right corner of the monitor
// focused when each arrived. The notification center lives in center/.
// Scripts reach the daemon with `qs ipc -c shell call notifications <function>`.
Scope {
  IpcHandler {
    target: "notifications"

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
}
