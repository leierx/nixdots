pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.common
import qs.nix
import "names.js" as Names

// BlueZ's default adapter and its devices; one click pairs, trusts and connects a new one.
Singleton {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool present: adapter !== null
  readonly property bool on: adapter?.enabled ?? false
  // While someone looks at the list: discovery keeps the radio busy.
  property bool scanning: false
  // Nameless devices nearby are only addresses, which nobody picks from a list.
  readonly property var devices: (adapter?.devices.values ?? []).filter(device => device.paired || device.connected || Names.clean(device.deviceName) !== "").sort((a, b) => rank(b) - rank(a) || Names.clean(a.name).localeCompare(Names.clean(b.name), undefined, { numeric: true }))
  readonly property var connected: devices.filter(device => device.connected)
  // What went wrong with each, by address, until it is tried again.
  property var failures: ({})
  // Paired here and to be connected once it is.
  property var pairing: []
  // Seen connecting, so going back to disconnected is a failure.
  property var connecting: []

  function rank(device: var): int {
    return device.connected ? 2 : device.paired ? 1 : 0;
  }

  function name(device: var): string {
    return Names.clean(device.name) || device.address;
  }

  function toggle(): void {
    if (root.adapter) root.adapter.enabled = !root.adapter.enabled;
  }

  function setFailure(address: string, message: string): void {
    const next = Object.assign({}, root.failures);
    if (message) next[address] = message;
    else delete next[address];
    root.failures = next;
  }

  function choose(device: var): void {
    root.setFailure(device.address, "");
    if (device.connected || device.state === BluetoothDeviceState.Connecting) {
      device.disconnect();
    } else if (device.paired) {
      device.connect();
    } else {
      root.pairing = [...root.pairing.filter(address => address !== device.address), device.address];
      device.pair();
    }
  }

  function settings(): void {
    Panels.close();
    Detached.run(["wezterm", "start", "--", "bluetui"], "");
  }

  // Material Symbols by the freedesktop icon BlueZ names the device with.
  function glyph(device: var): string {
    const icon = device.icon ?? "";
    if (/headset|headphone/.test(icon)) return Symbols.headphones;
    if (/keyboard/.test(icon)) return Symbols.keyboard;
    if (/mouse|tablet/.test(icon)) return Symbols.mouse;
    if (/phone/.test(icon)) return Symbols.phone;
    if (/audio|speaker|card/.test(icon)) return Symbols.speaker;
    return Symbols.devices;
  }

  // What a row says beside the name while something is under way or went wrong; the charge and the link are drawn.
  function note(device: var): string {
    if (root.failures[device.address]) return root.failures[device.address];
    if (device.pairing) return "Pairing…";
    if (device.state === BluetoothDeviceState.Connecting) return "Connecting…";
    if (device.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…";
    return "";
  }

  Binding {
    target: root.adapter
    property: "discovering"
    value: root.scanning && root.on
    when: root.adapter !== null && root.on
  }

  Instantiator {
    model: ScriptModel {
      values: root.adapter?.devices.values ?? []
    }

    Connections {
      required property var modelData

      target: modelData

      function onPairedChanged(): void {
        if (!modelData.paired || !root.pairing.includes(modelData.address)) return;
        root.pairing = root.pairing.filter(address => address !== modelData.address);
        // So it comes back by itself next time, as any pairing dialog does.
        modelData.trusted = true;
        modelData.connect();
      }

      function onPairingChanged(): void {
        if (modelData.pairing || modelData.paired || !root.pairing.includes(modelData.address)) return;
        root.pairing = root.pairing.filter(address => address !== modelData.address);
        // BlueZ without an agent pairs only what asks for no code.
        root.setFailure(modelData.address, "Needs a PIN: use Bluetooth Settings");
      }

      function onStateChanged(): void {
        const address = modelData.address;
        const was = root.connecting.includes(address);
        if (modelData.state === BluetoothDeviceState.Connecting) {
          if (!was) root.connecting = [...root.connecting, address];
        } else if (was && (modelData.state === BluetoothDeviceState.Connected || modelData.state === BluetoothDeviceState.Disconnected)) {
          root.connecting = root.connecting.filter(other => other !== address);
          if (modelData.state === BluetoothDeviceState.Disconnected) root.setFailure(address, "Couldn't connect");
        }
      }
    }
  }
}
