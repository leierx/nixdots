pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  property date now: minute(new Date())

  function minute(time: date): date {
    const minute = new Date(time);
    minute.setSeconds(0, 0);
    return minute;
  }

  // By the second, as Qt's timers stand still through a suspend; not a SystemClock, which spins at 1 ms through the hour a clock change repeats.
  Timer {
    interval: 1000
    repeat: true
    running: true
    onTriggered: {
      const now = new Date();
      const minute = root.minute(now);
      if (minute.getTime() !== root.now.getTime()) root.now = minute;
      // Just past each second, so a new minute shows as it comes.
      interval = 1005 - now.getMilliseconds();
    }
  }
}
