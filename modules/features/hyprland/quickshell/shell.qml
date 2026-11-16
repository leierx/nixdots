//@ pragma IconTheme Papirus-Dark
// Qt's high-DPI scaling: the QML keeps Adwaita's sizes and draws them 1.2× and sharp.
//@ pragma Env QT_SCALE_FACTOR=1.2

import Quickshell
import qs.bar
import qs.center
import qs.launcher
import qs.notifications
import qs.shortcuts

ShellRoot {
  Bar {}

  Launcher {}

  Notifications {}

  Center {}

  Shortcuts {}
}
