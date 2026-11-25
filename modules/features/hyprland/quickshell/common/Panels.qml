pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  property string active: ""
  // Keys have moved the focus in the open panel, so its focus ring shows.
  property bool keyboard: false
  // The center is one per screen, as the control centre is: `center:DP-1`.
  readonly property bool center: active.startsWith("center:")
  // What may open: one of these, or a screen's own panel on a screen that is up. Anything else would hold the clicks and the popups with nothing shown.
  property var names: ["apps", "clipboard", "monitors", "windows", "nixpkgs", "shortcuts", "power"]
  readonly property var perScreen: ["center", "controls", "tray-menu"]

  onActiveChanged: keyboard = false

  // A per-screen panel named bare, as a script does, opens on the focused screen.
  function named(name) {
    return ["center", "controls"].includes(name) ? `${name}:${Screens.focused}` : name;
  }

  function valid(name) {
    const colon = name.indexOf(":");
    if (colon < 0) return names.includes(name);
    return perScreen.includes(name.slice(0, colon)) && Screens.has(name.slice(colon + 1));
  }

  // With no monitor on, a panel would open on Hyprland's FALLBACK, unseen and holding the keyboard.
  function open(name) {
    const panel = named(name);
    if (Screens.real.length === 0) return;
    if (valid(panel)) active = panel;
    else if (!perScreen.includes(panel.split(":")[0])) console.warn(`Panels: no panel named ${panel}`);
  }

  function close() {
    active = "";
  }

  function toggle(name) {
    if (active === named(name)) close();
    else open(name);
  }

  // A screen's panel goes with it, whether or not its window says so.
  Connections {
    target: Screens

    function onRealChanged() {
      if (Panels.active !== "" && (Screens.real.length === 0 || !Panels.valid(Panels.active))) Panels.close();
    }
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
