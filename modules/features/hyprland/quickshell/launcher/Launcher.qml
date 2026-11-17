pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common

Scope {
  id: root

  readonly property list<LauncherMode> modes: [
    AppsMode {},
    ClipboardMode {},
    MonitorsMode {},
    WindowsMode {},
    NixpkgsMode {},
  ]
  readonly property LauncherMode mode: modes.find(mode => mode.open) ?? null
  // The window outlives its mode by a moment as it closes.
  property LauncherMode shown: null

  onModeChanged: if (mode) shown = mode

  Variants {
    model: root.modes

    GlobalShortcut {
      required property LauncherMode modelData

      name: `launcher-${modelData.name}`
      description: modelData.title
      onPressed: Panels.toggle(modelData.name)
    }
  }

  // Created as it opens, so every open starts from an empty search.
  LazyLoader {
    active: root.mode !== null

    LauncherWindow {
      mode: root.shown
    }
  }
}
