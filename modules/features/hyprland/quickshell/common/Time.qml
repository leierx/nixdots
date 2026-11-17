pragma Singleton

import Quickshell

Singleton {
  id: root

  property date now: minute(new Date())

  function minute(time: date): date {
    const minute = new Date(time);
    minute.setSeconds(0, 0);
    return minute;
  }

  // Ticking by the second, not the minute: Qt's timers stand still through a suspend, and a minute's would keep the old time up for most of one after it.
  SystemClock {
    precision: SystemClock.Seconds
    onDateChanged: {
      const minute = root.minute(date);
      if (minute.getTime() !== root.now.getTime()) root.now = minute;
    }
  }
}
