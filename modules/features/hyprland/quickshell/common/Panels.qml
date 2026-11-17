pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
  property string active: ""

  function open(name) {
    active = name;
  }

  function close() {
    active = "";
  }

  function toggle(name) {
    active = active === name ? "" : name;
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
