//@ pragma IconTheme Papirus-Dark

// The shell: one process holding every window. Keybinds and scripts drive it
// over IPC, for example `qs ipc -c shell call menu toggle apps`.

import Quickshell
import Quickshell.Io
import qs.menus
import qs.notifications
import qs.services

ShellRoot {
  IpcHandler {
    target: "menu"

    function open(name: string): void {
      MenuState.open(name);
    }

    function close(): void {
      MenuState.close();
    }

    function toggle(name: string): void {
      MenuState.toggle(name);
    }
  }

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

  // A menu is created when it opens and destroyed when it closes, so every
  // open starts from an empty search.
  LazyLoader {
    active: MenuState.activeMenu === "apps"

    AppsMenu {}
  }

  LazyLoader {
    active: MenuState.activeMenu === "clipboard"

    ClipboardMenu {}
  }

  LazyLoader {
    active: MenuState.activeMenu === "monitors"

    MonitorsMenu {}
  }

  LazyLoader {
    active: MenuState.activeMenu === "notifications"

    NotificationsMenu {}
  }
}
