pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// The laptop's battery as the bar shows it: UPower's display device, which
// combines every laptop battery and leaves out mice and UPSes. `fake` stands
// in for it, set over IPC to see the indicator on a machine without one.
Singleton {
  property var fake: null

  readonly property UPowerDevice device: UPower.displayDevice
  // Until UPower has answered, its values are zeros.
  readonly property bool present: fake !== null || (device.ready && device.isLaptopBattery && device.isPresent)
  readonly property int percent: fake?.percent ?? Math.round(device.percentage * 100)
  // On mains power, charging or full.
  readonly property bool plugged: fake?.plugged ?? !UPower.onBattery
  readonly property bool low: !plugged && percent <= 20
  readonly property bool critical: !plugged && percent <= 10
}
