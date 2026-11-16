//@ pragma IconTheme Papirus-Dark
// Qt's high-DPI scaling: the QML keeps Adwaita's sizes and draws them 1.2× and sharp.
//@ pragma Env QT_SCALE_FACTOR=1.2

// The shell: one process holding every window. Each component lives in its
// own directory and owns its IPC target; keybinds and scripts drive them, for
// example `qs ipc -c shell call launcher toggle apps`.

import Quickshell
import qs.bar
import qs.center
import qs.launcher
import qs.notifications

ShellRoot {
  Bar {}

  Launcher {}

  Notifications {}

  Center {}
}
