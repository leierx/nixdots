pragma Singleton

import Quickshell

Singleton {
  readonly property date now: clock.date

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }
}
