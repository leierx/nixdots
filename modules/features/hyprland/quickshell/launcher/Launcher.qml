import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.common

// The rofi-style pickers: apps, clipboard history and monitor layouts, opened
// by name with the global shortcuts `quickshell:launcher-<name>`, which
// Hyprland binds, or `qs ipc -c shell call launcher toggle <name>`. A picker
// is created when it opens and destroyed when it closes, so every open starts
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

  // Looks up every app's icon as the entries arrive: an icon Papirus lacks
  // costs thousands of failed stats through the inherited themes, which held
  // the first open long enough to miss the first keys typed.
  Connections {
    target: DesktopEntries.applications

    function onValuesChanged() {
      Qt.callLater(warmIcons);
    }

    // Called later, so a scan's entries, arriving one by one, are looked up once.
    function warmIcons() {
      for (const entry of DesktopEntries.applications.values) Quickshell.hasThemeIcon(entry.icon);
    }
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

  GlobalShortcut {
    name: "launcher-apps"
    description: "App launcher"
    onPressed: Panels.toggle("apps")
  }

  GlobalShortcut {
    name: "launcher-clipboard"
    description: "Clipboard history"
    onPressed: Panels.toggle("clipboard")
  }

  GlobalShortcut {
    name: "launcher-monitors"
    description: "Monitor layouts"
    onPressed: Panels.toggle("monitors")
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
