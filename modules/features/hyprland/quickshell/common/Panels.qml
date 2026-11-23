pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
  property string active: ""
  // The screen a centred panel was asked for, so a clock opens its menu where it was clicked rather than wherever Hyprland last focused.
  property string screen: ""
  // Keys have moved the focus in the open panel, so its focus ring shows.
  property bool keyboard: false

  onActiveChanged: keyboard = false

  // With no monitor on, a panel would open on Hyprland's FALLBACK, unseen and holding the keyboard.
  function open(name, screen) {
    if (Screens.real.length > 0) {
      Panels.screen = screen ?? "";
      active = name;
    }
  }

  function close() {
    active = "";
  }

  function toggle(name, screen) {
    if (active === name) close();
    else open(name, screen);
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
