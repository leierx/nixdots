//@ pragma IconTheme Papirus-Dark

// The shell: one process holding every window. Each part lives in its own
// directory and owns its IPC target; keybinds and scripts drive them, for
// example `qs ipc -c shell call launcher toggle apps`.

import Quickshell
import qs.launcher
import qs.notifications

ShellRoot {
  Launcher {}

  Notifications {}
}
