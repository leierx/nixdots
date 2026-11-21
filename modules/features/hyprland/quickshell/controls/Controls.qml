pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import qs.common
import qs.nix
import qs.notifications
import "names.js" as Names

// The control centre's own state: which of its menus is open, kept by name so it outlives a rebuilt list.
Singleton {
  id: root

  readonly property bool open: Panels.active.startsWith("controls:")
  property string menu: ""
  // The pills, those the machine has: hardware that is missing leaves none, a service that is missing a dim one.
  readonly property var toggles: {
    const list = [];
    if (!Net.present) {
      list.push({ key: "network", title: "Network", subtitle: "Not available", glyph: Symbols.wifiOff, on: false, menu: false, unavailable: true });
    } else {
      for (const device of Net.wired) list.push({ key: `wired:${device.name}`, title: Net.wired.length > 1 ? `Wired ${device.name}` : "Wired", subtitle: root.wiredState(device), glyph: Symbols.wired, on: device.connected, menu: false, unavailable: !device.hasLink, device });
      if (Net.wifi) list.push({ key: "wifi", title: "Wi-Fi", subtitle: root.wifiState(), glyph: Net.wifiGlyph, on: Net.wifiOn, menu: true, unavailable: Net.switchedOff });
      if (Net.vpns.length > 0) {
        const up = Net.vpns.filter(vpn => vpn.active);
        const busy = Net.operations.some(op => op.action === "up");
        list.push({ key: "vpn", title: "VPN", subtitle: busy && up.length === 0 ? "Connecting…" : up.map(vpn => Names.clean(vpn.name)).join(", ") || "Off", glyph: Symbols.vpn, on: up.length > 0, menu: true });
      }
    }
    if (BluetoothDevices.present) {
      const count = BluetoothDevices.connected.length;
      list.push({ key: "bluetooth", title: "Bluetooth", subtitle: !BluetoothDevices.on ? "Off" : count === 1 ? BluetoothDevices.name(BluetoothDevices.connected[0]) : count > 1 ? `${count} connected` : "On", glyph: BluetoothDevices.on ? Symbols.bluetooth : Symbols.bluetoothOff, on: BluetoothDevices.on, menu: true });
    }
    if (NightLight.present) list.push({ key: "night", title: "Night Light", subtitle: NightLight.on ? `${NightLight.temperature} K` : "Off", glyph: Symbols.nightLight, on: NightLight.on, menu: true });
    return list;
  }
  function wiredState(device: var): string {
    if (!device.hasLink) return "Cable unplugged";
    if (device.state === ConnectionState.Connecting) return "Connecting…";
    if (!device.connected) return "Off";
    if (Net.portal) return "Sign in to network";
    if (Net.limited) return "No internet";
    return device.linkSpeed >= 1000 ? Theme.unit(device.linkSpeed / 1000, "Gb/s") : device.linkSpeed > 0 ? Theme.unit(device.linkSpeed, "Mb/s") : "Connected";
  }

  function wifiState(): string {
    if (Net.switchedOff) return "Off by switch";
    if (!Net.wifiOn) return "Off";
    if (Net.networks.some(network => network.state === ConnectionState.Connecting)) return "Connecting…";
    if (!Net.connected) return "Not connected";
    if (Net.portal) return "Sign in to network";
    if (Net.limited) return "No internet";
    return Net.name(Net.connected);
  }

  function flip(toggle: var): void {
    if (toggle.unavailable) return;
    if (toggle.device) Net.toggleWired(toggle.device);
    else if (toggle.key === "wifi") Net.toggleWifi();
    else if (toggle.key === "vpn") Net.toggleVpns();
    else if (toggle.key === "bluetooth") BluetoothDevices.toggle();
    else if (toggle.key === "night") NightLight.toggle();
  }


  function toggle(): void {
    Panels.toggle(`controls:${Screens.focused}`);
  }

  // The header's actions, each closing the centre first.
  function screenshot(): void {
    Panels.close();
    shot.restart();
  }

  function lock(): void {
    Panels.close();
    locker.running = true;
  }

  function powerMenu(): void {
    Panels.open("power");
  }

  function show(name: string): void {
    root.menu = root.menu === name ? "" : name;
    if (root.menu !== "wifi") Net.cancel();
  }

  // Each opening starts with its menus shut, as GNOME's does.
  onOpenChanged: {
    if (open) return;
    root.menu = "";
    Net.cancel();
    Net.vpnAsking = "";
  }

  Binding {
    target: Net
    property: "scanning"
    value: root.open && root.menu === "wifi"
  }

  Binding {
    target: BluetoothDevices
    property: "scanning"
    value: root.open && root.menu === "bluetooth"
  }

  Binding {
    target: Media
    property: "watched"
    value: Panels.active === "center"
  }

  // Once the centre has faded, so the frozen screen is without it.
  Timer {
    id: shot

    interval: 250
    onTriggered: Detached.run(["freeze-region", "copy"], "")
  }

  Command {
    id: locker

    command: ["loginctl", "lock-session"]
  }

  GlobalShortcut {
    name: "controls"
    description: "Control centre"
    onPressed: root.toggle()
  }

  IpcHandler {
    target: "controls"

    function toggle(): void {
      Controls.toggle();
    }

    function menu(name: string): void {
      Controls.menu = name;
    }
  }
}
