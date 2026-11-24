pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
  property string active: ""
  // Keys have moved the focus in the open panel, so its focus ring shows.
  property bool keyboard: false
  // The center is one per screen, as the control centre is: `center:DP-1`.
  readonly property bool center: active.startsWith("center:")

  onActiveChanged: keyboard = false

  // A per-screen panel named bare, as a script does, opens on the focused screen.
  function named(name) {
    return ["center", "controls"].includes(name) ? `${name}:${Screens.focused}` : name;
  }

  // With no monitor on, a panel would open on Hyprland's FALLBACK, unseen and holding the keyboard.
  function open(name) {
    if (Screens.real.length > 0) active = named(name);
  }

  function close() {
    active = "";
  }

  function toggle(name) {
    if (active === named(name)) close();
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
