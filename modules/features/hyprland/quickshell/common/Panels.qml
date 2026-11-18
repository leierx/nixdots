pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
  property string active: ""

  // With no monitor on, a panel would open on Hyprland's FALLBACK, unseen and holding the keyboard.
  function open(name) {
    if (Screens.real.length > 0) active = name;
  }

  function close() {
    active = "";
  }

  function toggle(name) {
    if (active === name) close();
    else open(name);
  }

  IpcHandler {
    target: "panels"

    function open(name: string): void {
      Panels.open(name);
    }

    function close(): void {
      Panels.close();
    }

    function toggle(name: string): void {
      Panels.toggle(name);
    }
  }
}
