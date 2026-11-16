import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common

// A picker is created as it opens, so every open starts from an empty search.
Scope {
  // On a first open the entries arrived one by one, each rebuilding the list.
  Component.onCompleted: {
    DesktopEntries.applications.values;
    AppUsage.week;
    Quickshell.hasThemeIcon("application-x-executable");
  }

  // An icon Papirus lacks costs thousands of failed stats, enough to miss the first keys typed.
  Connections {
    target: DesktopEntries.applications

    function onValuesChanged() {
      Qt.callLater(warmIcons);
    }

    // Later, so a scan's entries, arriving one by one, are looked up once.
    function warmIcons() {
      for (const entry of DesktopEntries.applications.values) Quickshell.hasThemeIcon(entry.icon);
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
