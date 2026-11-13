//@ pragma IconTheme Papirus-Dark

// The shell: one process holding every window. Keybinds and scripts drive it
// over IPC, for example `qs ipc call menu toggle apps`.

import Quickshell
import Quickshell.Io
import qs.menus
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

  // A menu is created when it opens and destroyed when it closes, so every
  // open starts from an empty search.
  LazyLoader {
    active: MenuState.activeMenu === "apps"

    AppsMenu {}
  }
}
