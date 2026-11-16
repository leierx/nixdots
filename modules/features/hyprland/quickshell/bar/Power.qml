pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// UPower's display device combines the laptop batteries and leaves out mice and UPSes.
Singleton {
  property var fake: null

  readonly property UPowerDevice device: UPower.displayDevice
  // Until UPower has answered, its values are zeros.
  readonly property bool present: fake !== null || (device.ready && device.isLaptopBattery && device.isPresent)
  readonly property int percent: fake?.percent ?? Math.round(device.percentage * 100)
  readonly property bool plugged: fake?.plugged ?? !UPower.onBattery
  readonly property bool low: !plugged && percent <= 25
  readonly property bool critical: !plugged && percent <= 10
}
