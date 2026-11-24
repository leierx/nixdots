import Quickshell
import Quickshell.Io

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

  // Reads Notifs from the start, so its server runs with no monitor on to show a popup.
  PictureCopies {}

  NotificationPopups {}
}
