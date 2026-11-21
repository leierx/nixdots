pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.common

// UPower's display device combines the laptop batteries and leaves out mice and UPSes.
Singleton {
  readonly property UPowerDevice device: UPower.displayDevice
  // Until UPower has answered, its values are zeros.
  readonly property bool present: device.ready && device.isLaptopBattery && device.isPresent
  readonly property int percent: Math.round(device.percentage * 100)
  readonly property bool plugged: !UPower.onBattery
  readonly property bool charging: device.state === UPowerDeviceState.Charging
  // Seconds until empty on battery, or until full while charging; 0 while UPower is still estimating.
  readonly property real remaining: charging ? device.timeToFull : plugged ? 0 : device.timeToEmpty

  function duration(seconds: real): string {
    const minutes = Math.round(seconds / 60);
    const hours = Math.floor(minutes / 60);
    return hours > 0 ? `${Theme.unit(hours, "h")} ${Theme.unit(minutes % 60, "min")}` : Theme.unit(minutes, "min");
  }
}
