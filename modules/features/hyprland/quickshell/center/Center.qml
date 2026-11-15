import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// The notification center with its calendar, dropping down from the middle of
// the bar, opened with `qs ipc -c shell call center toggle`. It is created as
// it opens, so every group starts collapsed, and unloaded once it has
// animated closed.
Scope {
  IpcHandler {
    target: "center"

    function open(): void {
      Panels.open("center");
    }

    function close(): void {
      if (Panels.active === "center") Panels.close();
    }

    function toggle(): void {
      Panels.toggle("center");
    }
  }

  LazyLoader {
    id: loader

    NotificationCenter {
      onHidden: loader.active = false
    }
  }

  Connections {
    target: Panels

    function onActiveChanged() {
      if (Panels.active === "center") loader.active = true;
    }
  }
}
