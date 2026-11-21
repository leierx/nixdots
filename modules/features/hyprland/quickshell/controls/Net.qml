pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.common
import qs.nix
import qs.notifications
import "names.js" as Names

// NetworkManager: Wi-Fi and wired through Quickshell, and through nmcli what Quickshell lacks (VPNs, whether it runs at all).
Singleton {
  id: root

  // nmcli's word on NetworkManager, which Quickshell keeps no record of once it goes.
  property bool running: false
  readonly property bool present: running || devices.length > 0
  readonly property var devices: Networking.devices.values
  // The first card; a second is rare enough to leave to Network Settings.
  readonly property var wifi: devices.find(device => device.type === DeviceType.Wifi) ?? null
  readonly property var wired: devices.filter(device => device.type === DeviceType.Wired)
  readonly property bool wifiOn: Networking.wifiEnabled && Networking.wifiHardwareEnabled
  readonly property bool switchedOff: !Networking.wifiHardwareEnabled
  // While someone looks at the list: a scan every ten seconds costs power.
  property bool scanning: false
  readonly property var networks: wifi && wifiOn ? wifi.networks.values : []
  readonly property var connected: networks.find(network => network.connected) ?? null
  readonly property bool wiredUp: wired.some(device => device.connected)
  readonly property bool portal: Networking.connectivity === NetworkConnectivity.Portal
  readonly property bool limited: (connected !== null || wiredUp) && (Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.None)

  // The network a password is asked for, why it is asked again, and those this shell saved a profile for that never connected.
  property string asking: ""
  property string askError: ""
  property var created: []
  // The network just tried, and what last went wrong with each.
  property string attempt: ""
  property var failures: ({})

  // nmcli's WireGuard and VPN profiles: { name, uuid, type, active, state }.
  property var vpns: []
  // What is being done to each, by uuid, and the one asking for a password.
  property var operations: []
  property string vpnAsking: ""
  property string vpnError: ""

  readonly property string wifiGlyph: !wifiOn ? Symbols.wifiOff : connected && portal ? Symbols.wifiPortal : connected && limited ? Symbols.wifiBad : connected ? signalGlyph(connected.signalStrength) : Symbols.wifi0
  // What the bar shows: the link in use, wired before Wi-Fi.
  readonly property string glyph: !present ? "" : wiredUp ? Symbols.wired : wifi ? wifiGlyph : ""

  function signalGlyph(strength: real): string {
    return strength > 0.75 ? Symbols.wifi4 : strength > 0.5 ? Symbols.wifi3 : strength > 0.25 ? Symbols.wifi2 : strength > 0.05 ? Symbols.wifi1 : Symbols.wifi0;
  }

  function name(network: var): string {
    return Names.clean(network?.name ?? "");
  }

  function secured(network: var): bool {
    return ![WifiSecurityType.Open, WifiSecurityType.Owe].includes(network.security);
  }

  // Asks for a username and certificates the shell has no way to ask for.
  function enterprise(network: var): bool {
    return [WifiSecurityType.Wpa2Eap, WifiSecurityType.WpaEap, WifiSecurityType.Wpa3SuiteB192, WifiSecurityType.Leap, WifiSecurityType.DynamicWep].includes(network.security);
  }

  function find(ssid: string): var {
    return root.networks.find(network => network.name === ssid) ?? null;
  }

  function toggleWifi(): void {
    if (!root.switchedOff) Networking.wifiEnabled = !Networking.wifiEnabled;
  }

  // One click, one action: off if on, on if it can be, a password asked for if it needs one.
  function choose(network: var): void {
    const ssid = network.name;
    root.setFailure(ssid, "");
    if (network.connected || network.state === ConnectionState.Connecting) {
      network.disconnect();
    } else if (root.enterprise(network) && !network.known) {
      root.settings(["--create", "--type=802-11-wireless"]);
    } else if (network.known || !root.secured(network)) {
      root.attempt = ssid;
      network.connect();
    } else {
      root.ask(ssid);
    }
  }

  function ask(ssid: string): void {
    root.cancel();
    root.asking = ssid;
    root.askError = "";
  }

  function submit(ssid: string, password: string): void {
    const network = root.find(ssid);
    if (!network) {
      root.askError = "Out of range";
      return;
    }
    if (!network.known && !root.created.includes(ssid)) root.created = [...root.created, ssid];
    root.attempt = ssid;
    root.askError = "";
    network.connectWithPsk(password);
  }

  // A profile saved for a password that never worked goes again, as nothing else would clean it up.
  function cancel(): void {
    const ssid = root.asking;
    root.asking = "";
    root.askError = "";
    if (!root.created.includes(ssid)) return;
    root.created = root.created.filter(other => other !== ssid);
    const network = root.find(ssid);
    if (network && !network.connected) network.forget();
  }

  function setFailure(ssid: string, message: string): void {
    const next = Object.assign({}, root.failures);
    if (message) next[ssid] = message;
    else delete next[ssid];
    root.failures = next;
  }

  function failed(network: var, reason: int): void {
    const ssid = network.name;
    if (ssid !== root.attempt && ssid !== root.asking) return;
    if (reason === ConnectionFailReason.NoSecrets && root.secured(network) && !root.enterprise(network)) {
      root.askError = root.asking === ssid || root.created.includes(ssid) ? "Wrong password" : "Password needed";
      root.asking = ssid;
    } else {
      root.setFailure(ssid, reason === ConnectionFailReason.WifiNetworkLost ? "Out of range" : "Couldn't connect");
    }
  }

  function toggleWired(device: var): void {
    if (device.connected) device.disconnect();
    else if (device.network) device.network.connect();
  }

  function settings(extra: var): void {
    Panels.close();
    Detached.run(["nm-connection-editor", ...extra], "");
  }

  function signIn(): void {
    Panels.close();
    Detached.run(["xdg-open", "http://neverssl.com/"], "");
  }

  function toggleVpn(uuid: string): void {
    const vpn = root.vpns.find(profile => profile.uuid === uuid);
    if (!vpn) return;
    root.vpnAsking = "";
    root.run(uuid, vpn.active ? "down" : "up", "");
  }

  // The pill: all of them down if any is up, otherwise the first.
  function toggleVpns(): void {
    const up = root.vpns.filter(vpn => vpn.active);
    if (up.length > 0) for (const vpn of up) root.run(vpn.uuid, "down", "");
    else if (root.vpns.length > 0) root.run(root.vpns[0].uuid, "up", "");
  }

  function vpnPassword(uuid: string, password: string): void {
    root.vpnAsking = "";
    root.vpnError = "";
    root.run(uuid, "up", password);
  }

  // A newer action on a profile replaces one still running, so the last click wins.
  function run(uuid: string, action: string, secret: string): void {
    root.operations = [...root.operations.filter(op => op.uuid !== uuid), { uuid, action, secret, key: `${uuid}:${Date.now()}:${Math.random()}` }];
  }

  function finished(key: string, uuid: string, action: string, withSecret: bool, ok: bool, message: string): void {
    root.operations = root.operations.filter(op => op.key !== key);
    vpnList.refresh();
    if (ok) return;
    const vpn = root.vpns.find(profile => profile.uuid === uuid);
    if (action === "up" && /secret|password/i.test(message)) {
      root.vpnAsking = uuid;
      root.vpnError = withSecret ? "Wrong password" : "";
      return;
    }
    Quickshell.execDetached(["notify-send", "-a", "Network", "-i", "network-vpn", `${vpn ? Names.clean(vpn.name) : "VPN"} ${action === "up" ? "Failed to Connect" : "Failed to Disconnect"}`, message || "nmcli failed"]);
  }

  function busy(uuid: string): string {
    return root.operations.find(op => op.uuid === uuid)?.action ?? "";
  }

  // nmcli -t escapes its separator and backslash.
  function fields(line: string): var {
    const out = [];
    let field = "";
    for (let i = 0; i < line.length; i++) {
      if (line[i] === "\\" && i + 1 < line.length) field += line[++i];
      else if (line[i] === ":") {
        out.push(field);
        field = "";
      } else field += line[i];
    }
    out.push(field);
    return out;
  }

  Binding {
    target: root.wifi
    property: "scannerEnabled"
    value: root.scanning
    when: root.wifi !== null
  }

  Instantiator {
    model: root.networks

    Connections {
      required property var modelData

      target: modelData

      function onConnectionFailed(reason: int): void {
        root.failed(modelData, reason);
      }

      function onConnectedChanged(): void {
        if (!modelData.connected) return;
        root.created = root.created.filter(ssid => ssid !== modelData.name);
        root.setFailure(modelData.name, "");
        if (root.asking === modelData.name) {
          root.asking = "";
          root.askError = "";
        }
      }
    }
  }

  Instantiator {
    model: root.operations

    Process {
      id: op

      required property var modelData

      running: true
      command: ["nmcli", "--wait", "30", "connection", modelData.action, "uuid", modelData.uuid, ...(modelData.secret ? ["passwd-file", "/dev/stdin"] : [])]
      stdinEnabled: modelData.secret !== ""
      stderr: StdioCollector {
        id: err
      }
      onStarted: if (modelData.secret) {
        write(`vpn.secrets.password:${modelData.secret}\n`);
        stdinEnabled = false;
      }
      onExited: code => root.finished(modelData.key, modelData.uuid, modelData.action, modelData.secret !== "", code === 0, err.text.trim().replace(/^Error: /, ""))
    }
  }

  // The portal's own page: any plain http address it can hijack.
  Process {
    id: portalNote

    // Its card's id, printed first, so the card goes when the portal does.
    property int card: 0

    command: ["notify-send", "-p", "-a", "Network", "-i", "network-wireless", "-A", "sign-in=Sign In", "Sign In to Network", "This network wants a sign-in before it lets anything through"]
    stdout: SplitParser {
      onRead: line => {
        const text = line.trim();
        if (portalNote.card === 0 && /^\d+$/.test(text)) portalNote.card = Number(text);
        else if (text === "sign-in") root.signIn();
      }
    }
  }

  onPortalChanged: {
    if (root.portal) {
      portalNote.card = 0;
      portalNote.running = true;
      recheck.start();
    } else {
      Notifs.close(portalNote.card);
      portalNote.running = false;
    }
  }

  // Signing in happens in the browser, which says nothing to NetworkManager.
  Timer {
    id: recheck

    interval: 10000
    repeat: true
    running: root.portal
    onTriggered: Networking.checkConnectivity()
  }

  // Every change NetworkManager makes, and whether it runs: "is running", "has started", "is stopped", "not running".
  Process {
    id: monitor

    property int failures: 0

    running: true
    command: ["nmcli", "monitor"]
    stdout: SplitParser {
      onRead: line => {
        monitor.failures = 0;
        if (/is running|has started/.test(line)) root.running = true;
        else if (/is stopped|not running|has stopped/.test(line)) root.running = false;
        settle.restart();
      }
    }
    onRunningChanged: {
      if (running) return;
      // Backing off, so a machine without nmcli does not fill the log.
      restart.interval = Math.min(2000 * 2 ** failures, 300000);
      failures++;
      restart.start();
    }
  }

  Timer {
    id: restart

    onTriggered: monitor.running = true
  }

  // A change comes as a burst of lines.
  Timer {
    id: settle

    interval: 150
    onTriggered: vpnList.refresh()
  }

  Process {
    id: vpnList

    function refresh(): void {
      if (running) again = true;
      else running = true;
    }

    property bool again: false

    command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,ACTIVE,STATE", "connection", "show"]
    stdout: StdioCollector {
      onStreamFinished: {
        const vpns = [];
        for (const line of text.split("\n")) {
          if (!line) continue;
          const [name, uuid, type, active, state] = root.fields(line);
          if (type === "wireguard" || type === "vpn") vpns.push({ name, uuid, type, active: active === "yes", state });
        }
        // By name, so the list keeps still as they come and go.
        root.vpns = vpns.sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true }));
      }
    }
    onExited: code => {
      root.running = code === 0;
      if (code !== 0) root.vpns = [];
      if (again) {
        again = false;
        running = true;
      }
    }
  }

  Component.onCompleted: vpnList.refresh()
}
