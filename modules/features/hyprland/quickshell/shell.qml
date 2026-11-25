//@ pragma IconTheme Papirus-Dark

import QtQuick
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
import qs.tooltip

ShellRoot {
  id: root

  // Another shell of this config already up (one run by hand beside the unit's): this one goes before it shows anything; a check that fails starts it anyway, as no shell at all is worse.
  property bool alone: false
  // Without a UTF-8 locale qs says so on stdout, ahead of the list.
  readonly property var listing: ({ LC_ALL: "C.UTF-8" })

  Command {
    name: "Looking for another shell"
    quiet: true
    timeout: 2000
    running: true
    command: ["qs", "list", "--all", "--json"]
    environment: root.listing
    onDone: output => {
      let all = [];
      try {
        all = JSON.parse(output).filter(instance => instance.shell_id === Quickshell.shellId);
      } catch (error) {
        console.warn(`Looking for another shell: ${error}`);
      }
      const own = all.find(instance => instance.pid === Quickshell.processId);
      // Seconds only, so a start in the same one goes by pid: both shells agree which stays.
      const before = instance => instance.launch_time < own.launch_time || instance.launch_time === own.launch_time && instance.pid < own.pid;
      if (own && all.some(instance => instance.pid !== own.pid && before(instance))) {
        console.info("Another shell of this config is running: quitting");
        Qt.quit();
      } else {
        root.alone = true;
      }
    }
    onFailed: root.alone = true
  }

  LazyLoader {
    active: root.alone

    Scope {
      ClickAway {}

      Bar {}

      Launcher {}

      Notifications {}

      Center {}

      Shortcuts {}

      Power {}

      OsdPopup {}

      Idle {}

      Tooltip {}
    }
  }
}
