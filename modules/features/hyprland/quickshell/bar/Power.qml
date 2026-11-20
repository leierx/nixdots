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
  readonly property bool charging: fake ? fake.plugged && fake.percent < 100 : device.state === UPowerDeviceState.Charging
  // Seconds until empty on battery, or until full while charging; 0 while UPower is still estimating.
  readonly property real remaining: fake ? (fake.plugged ? 4200 : 9600) : charging ? device.timeToFull : plugged ? 0 : device.timeToEmpty
  readonly property bool low: !plugged && percent <= 25
  readonly property bool critical: !plugged && percent <= 10

  function duration(seconds: real): string {
    const minutes = Math.round(seconds / 60);
    const hours = Math.floor(minutes / 60);
    return hours > 0 ? `${hours} h ${minutes % 60} min` : `${minutes} min`;
  }
}
