pragma Singleton

import Quickshell
import Quickshell.Hyprland

// Hyprland stands a headless FALLBACK output in while no monitor is on, which nobody can see.
Singleton {
  id: root

  readonly property string fallback: "FALLBACK"
  readonly property var real: Quickshell.screens.filter(screen => screen.name !== fallback)
  // Hyprland reports focus on a monitor that has just gone for a moment, so the first one stands in.
  readonly property string focused: {
    const name = Hyprland.focusedMonitor?.name ?? "";
    return has(name) ? name : real[0]?.name ?? "";
  }

  function has(name: string): bool {
    return root.real.some(screen => screen.name === name);
  }
}
