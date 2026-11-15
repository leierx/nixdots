import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// The rofi-style pickers: apps, clipboard history and monitor layouts, opened
// by name with `qs ipc -c shell call launcher toggle <name>`. A picker is
// created when it opens and destroyed when it closes, so every open starts
// from an empty search.
Scope {
  // Loads the desktop entries, icon theme and app use at startup: on the first
  // open the entries arrived one by one, each rebuilding the list, and held the
  // picker up.
  Component.onCompleted: {
    DesktopEntries.applications.values;
    AppUsage.week;
    Quickshell.hasThemeIcon("application-x-executable");
  }

  IpcHandler {
    target: "launcher"

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

  LazyLoader {
    active: Panels.active === "apps"

    AppsMenu {}
  }

  LazyLoader {
    active: Panels.active === "clipboard"

    ClipboardMenu {}
  }

  LazyLoader {
    active: Panels.active === "monitors"

    MonitorsMenu {}
  }
}
