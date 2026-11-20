//@ pragma IconTheme Papirus-Dark
// Qt's high-DPI scaling: the QML keeps Adwaita's sizes and draws them 1.2× and sharp.
//@ pragma Env QT_SCALE_FACTOR=1.2

import Quickshell
import qs.common
import qs.bar
import qs.center
import qs.idle
import qs.launcher
import qs.notifications
import qs.osd
import qs.power
import qs.shortcuts

ShellRoot {
  ClickAway {}

  Bar {}

  Launcher {}

  Notifications {}

  Center {}

  Shortcuts {}

  Power {}

  OsdPopup {}

  Idle {}
}
