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

Singleton {
  id: root

  // nmcli's messages are matched in English; plain C would print every name past ASCII as "?".
  readonly property var nmcliEnvironment: ({ LC_ALL: "C.UTF-8" })

  // nmcli's word on NetworkManager, which Quickshell keeps no record of once it goes.
  property bool running: false
  readonly property bool present: running || devices.length > 0
  readonly property var devices: Networking.devices.values
  readonly property var wifis: devices.filter(device => device.type === DeviceType.Wifi)
  readonly property var wired: devices.filter(device => device.type === DeviceType.Wired)
  readonly property bool wifiOn: Networking.wifiEnabled && Networking.wifiHardwareEnabled
  readonly property bool switchedOff: !Networking.wifiHardwareEnabled
  // While someone looks at the list: a scan every ten seconds costs power.
  property bool scanning: false
  // Every card's, each network its card's own.
  readonly property var networks: wifiOn ? [].concat(...wifis.map(device => device.networks.values)) : []
  readonly property var connected: networks.find(network => network.connected) ?? null
  readonly property bool wiredUp: wired.some(device => device.connected)
  readonly property bool portal: Networking.connectivity === NetworkConnectivity.Portal
  readonly property bool online: Networking.connectivity === NetworkConnectivity.Full
  readonly property bool limited: (connected !== null || wiredUp) && (Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.None)
  // A portal blocks DNS over TLS until signed in, so NetworkManager's check never resolves to see one: Wi-Fi without internet may be one too.
  readonly property bool signInOffered: connected !== null && (portal || limited)
  // The Wi-Fi device whose connection takes the network's own DNS until it is online; NetworkManager drops that with the connection. Saved, as the change outlives a shell restarted mid-sign-in.
  property alias relaxed: saved.relaxed
  // The network it was relaxed for: on another the flag is stale, as NetworkManager dropped the change.
  property alias relaxedFor: saved.relaxedFor

  // The network a password is asked for, on which card, why it is asked again, and those this shell saved a profile for that never connected.
  property string asking: ""
  property string askingOn: ""
  property string askError: ""
  // The hidden network asked for: { ssid, password, error, busy }, until it connects or is given up.
  property var hidden: null
  property var created: []
  // The network a password was just sent for, until NetworkManager says how it went.
  property string trying: ""
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
  readonly property string glyph: !present ? "" : wiredUp ? Symbols.wired : wifis.length > 0 ? wifiGlyph : ""

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

  function bytes(text: string): int {
    return encodeURIComponent(text).replace(/%[0-9A-F]{2}/g, "x").length;
  }

  // NetworkManager's rule for a WPA key, which it refuses on a saved profile without a word reaching the shell; SAE takes any.
  function pskProblem(password: string, security: int): string {
    if (security === WifiSecurityType.Sae) return "";
    if (root.bytes(password) < 8) return "Password too short";
    return root.bytes(password) > 63 && !/^[0-9a-fA-F]{64}$/.test(password) ? "Password too long" : "";
  }

  // On the card named, if it sees it.
  function find(ssid: string, card: string): var {
    const all = root.networks.filter(network => network.name === ssid);
    return all.find(network => network.device?.name === card) ?? all[0] ?? null;
  }

  function toggleWifi(): void {
    if (!root.switchedOff) Networking.wifiEnabled = !Networking.wifiEnabled;
  }

  // One click, one action: off if on, on if it can be, a password asked for if it needs one.
  function choose(network: var): void {
    const ssid = network.name;
    root.setFailure(ssid, "");
    if (network.connected || network.state === ConnectionState.Connecting) {
      if (root.trying === ssid) root.trying = "";
      // A profile this shell saved that never connected goes with the attempt.
      if (!network.connected && root.created.includes(ssid)) {
        root.created = root.created.filter(other => other !== ssid);
        network.forget();
      } else {
        network.disconnect();
      }
    } else if (root.enterprise(network) && !network.known) {
      root.settings(["--create", "--type=802-11-wireless"]);
    } else if (network.known || !root.secured(network)) {
      root.attempt = ssid;
      network.connect();
    } else {
      root.ask(ssid, network.device?.name ?? "");
    }
  }

  function ask(ssid: string, card: string): void {
    root.cancel();
    root.asking = ssid;
    root.askingOn = card;
    root.askError = "";
  }

  function submit(ssid: string, password: string): void {
    const network = root.find(ssid, root.askingOn);
    if (!network) {
      root.askError = "Out of range";
      return;
    }
    const problem = root.pskProblem(password, network.security);
    if (problem) {
      root.askError = problem;
      return;
    }
    if (!network.known && !root.created.includes(ssid)) root.created = [...root.created, ssid];
    root.attempt = ssid;
    root.trying = ssid;
    root.askError = "";
    network.connectWithPsk(password);
  }

  // A profile saved for a password that never worked goes again, as nothing else would clean it up; one still being tried waits for how it went.
  function cancel(): void {
    const ssids = [root.asking, root.hidden?.ssid ?? ""];
    root.asking = "";
    root.askingOn = "";
    root.askError = "";
    root.hidden = null;
    for (const ssid of ssids) {
      if (ssid === "" || !root.created.includes(ssid) || root.trying === ssid) continue;
      root.created = root.created.filter(other => other !== ssid);
      const network = root.find(ssid, "");
      if (network && !network.connected) network.forget();
    }
  }

  function askHidden(): void {
    root.cancel();
    root.hidden = { ssid: "", password: "", error: "", busy: false };
  }

  // A profile first, as NetworkManager only joins a network it cannot see from one marked hidden; the password goes over D-Bus once it is there, never on a command line.
  function connectHidden(ssid: string, password: string): void {
    if (!root.hidden || root.hidden.busy) return;
    root.setFailure(ssid, "");
    // 802.11's limit, in bytes.
    if (root.bytes(ssid) > 32) {
      root.hidden = { ssid, password, error: "Name too long", busy: false };
      return;
    }
    const network = root.find(ssid, "");
    // A profile made here is WPA-PSK's.
    const problem = password === "" ? "" : root.pskProblem(password, network?.known ? network.security : WifiSecurityType.Wpa2Psk);
    if (problem) {
      root.hidden = { ssid, password, error: problem, busy: false };
      return;
    }
    root.hidden = { ssid, password, error: "", busy: true };
    if (network?.known) {
      root.joinHidden();
    } else {
      addHidden.ssid = ssid;
      addHidden.running = true;
    }
  }

  function joinHidden(): void {
    const ssid = root.hidden?.ssid ?? "";
    const network = root.hidden?.busy && root.trying !== ssid ? root.find(ssid, "") : null;
    if (!network?.known) return;
    root.attempt = ssid;
    root.trying = ssid;
    if (root.hidden.password !== "") network.connectWithPsk(root.hidden.password);
    else network.connect();
  }

  onNetworksChanged: if (root.hidden?.busy && !addHidden.running) Qt.callLater(root.joinHidden)
  // Gone mid-attempt, NetworkManager will never say how it went.
  onPresentChanged: {
    if (root.present) return;
    root.attempt = "";
    root.trying = "";
    if (root.hidden?.busy) root.hidden = Object.assign({}, root.hidden, { busy: false });
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
    if (root.attempt === ssid) root.attempt = "";
    if (root.trying === ssid) root.trying = "";
    const noSecrets = reason === ConnectionFailReason.NoSecrets && root.secured(network) && !root.enterprise(network);
    // Asked for by name: the prompt says why, with what was typed, and the profile goes until it works.
    if (root.hidden?.ssid === ssid) {
      if (root.created.includes(ssid)) {
        root.created = root.created.filter(other => other !== ssid);
        network.forget();
      }
      root.hidden = Object.assign({}, root.hidden, { busy: false, error: noSecrets ? "Wrong password" : reason === ConnectionFailReason.WifiNetworkLost ? "Not found" : "Couldn't connect" });
      return;
    }
    // Its prompt shut while it was tried: nobody is there to ask again.
    if (root.asking !== ssid && root.created.includes(ssid)) {
      root.created = root.created.filter(other => other !== ssid);
      network.forget();
      root.setFailure(ssid, noSecrets ? "Wrong password" : "Couldn't connect");
      return;
    }
    if (noSecrets) {
      root.askError = root.asking === ssid || root.created.includes(ssid) ? "Wrong password" : "Password needed";
      root.asking = ssid;
      root.askingOn = network.device?.name ?? "";
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
    // Seen as a portal, its check resolved: DNS works as it is.
    if (root.portal || root.relaxed !== "" || !root.connected) root.openPortal();
    else relax.running = true;
  }

  function openPortal(): void {
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

  Instantiator {
    model: ScriptModel {
      values: root.wifis
    }

    Binding {
      required property var modelData

      target: modelData
      property: "scannerEnabled"
      value: root.scanning
    }
  }

  Instantiator {
    model: ScriptModel {
      values: root.networks
    }

    Connections {
      required property var modelData

      target: modelData

      function onConnectionFailed(reason: int): void {
        root.failed(modelData, reason);
      }

      function onConnectedChanged(): void {
        if (!modelData.connected) return;
        // Done with: a later drop is no failure of this attempt.
        if (root.attempt === modelData.name) root.attempt = "";
        root.created = root.created.filter(ssid => ssid !== modelData.name);
        if (root.trying === modelData.name) root.trying = "";
        root.setFailure(modelData.name, "");
        if (root.asking === modelData.name) {
          root.asking = "";
          root.askingOn = "";
          root.askError = "";
        }
        if (root.hidden?.ssid === modelData.name) root.hidden = null;
      }
    }
  }

  // Keyed, so an action on one profile leaves another's nmcli running.
  Instantiator {
    model: ScriptModel {
      values: root.operations
      objectProp: "key"
    }

    Process {
      id: op

      required property var modelData
      property bool exitReported: false

      running: true
      command: ["nmcli", "--wait", "30", "connection", modelData.action, "uuid", modelData.uuid, ...(modelData.secret ? ["passwd-file", "/dev/stdin"] : [])]
      environment: root.nmcliEnvironment
      stdinEnabled: modelData.secret !== ""
      stderr: StdioCollector {
        id: err
      }
      onStarted: if (modelData.secret) {
        write(`vpn.secrets.password:${modelData.secret}\n`);
        stdinEnabled = false;
      }
      onExited: code => {
        op.exitReported = true;
        root.finished(modelData.key, modelData.uuid, modelData.action, modelData.secret !== "", code === 0, err.text.trim().replace(/^Error: /, ""));
      }
      // One that fails to start reports no exit, as Command's.
      onRunningChanged: {
        if (op.running) return;
        if (!op.exitReported) root.finished(modelData.key, modelData.uuid, modelData.action, modelData.secret !== "", false, `${op.command[0]} could not be started`);
        op.exitReported = false;
      }
    }
  }

  // The portal's own page: any plain http address it can hijack.
  Process {
    id: portalNote

    // Its card's id, printed first, so the card goes when the portal does.
    property int card: 0

    command: ["notify-send", "-p", "-e", "-h", "string:x-canonical-private-synchronous:network-portal", "-a", "Network", "-i", "network-wireless", "-A", "sign-in=Sign In", "Sign In to Network", "This network wants a sign-in before it lets anything through"]
    stdout: SplitParser {
      onRead: line => {
        const text = line.trim();
        if (portalNote.card === 0 && /^\d+$/.test(text)) portalNote.card = Number(text);
        else if (text === "sign-in") root.signIn();
      }
    }
  }

  // For this connection only, never the saved profile: the network's own DNS, without TLS, which the portal answers.
  Command {
    id: relax

    name: "Signing In to Network"
    command: ["nmcli", "device", "modify", root.connected?.device?.name ?? "", "ipv4.ignore-auto-dns", "no", "ipv6.ignore-auto-dns", "no", "connection.dns-over-tls", "no"]
    environment: root.nmcliEnvironment
    onDone: {
      root.relaxed = root.connected?.device?.name ?? "";
      root.relaxedFor = root.connected?.name ?? "";
      Networking.checkConnectivity();
      root.openPortal();
    }
  }

  // WPA's pre-shared key, or open; on no card in particular, as the profile goes to whichever finds it.
  Command {
    id: addHidden

    // What it was started for, as the prompt may go while it runs.
    property string ssid: ""

    name: "Hidden network"
    quiet: true
    command: ["nmcli", "connection", "add", "type", "wifi", "con-name", ssid, "ssid", ssid, "802-11-wireless.hidden", "yes", ...(root.hidden?.password ? ["wifi-sec.key-mgmt", "wpa-psk"] : [])]
    environment: root.nmcliEnvironment
    onDone: output => {
      if (root.hidden?.ssid !== addHidden.ssid) {
        // Given up on meanwhile: nothing will connect with it.
        const uuid = /\(([0-9a-f-]{36})\)/.exec(output)?.[1];
        if (uuid) Quickshell.execDetached(["nmcli", "connection", "delete", "uuid", uuid]);
        return;
      }
      if (!root.created.includes(addHidden.ssid)) root.created = [...root.created, addHidden.ssid];
      root.joinHidden();
    }
    onFailed: if (root.hidden?.ssid === addHidden.ssid) root.hidden = Object.assign({}, root.hidden, { busy: false, error: "Couldn't connect" })
  }

  // Online, the saved profile's DNS again; failing means the connection, and the change with it, has gone.
  function restrict(): void {
    if (root.online && root.relaxed !== "" && !strict.running) strict.running = true;
  }

  onOnlineChanged: restrict()
  onRelaxedChanged: restrict()
  onConnectedChanged: if (root.relaxed !== "" && root.connected !== null && root.connected.name !== root.relaxedFor) root.relaxed = ""

  Command {
    id: strict

    name: "Network: back to its own DNS"
    quiet: true
    command: ["nmcli", "device", "reapply", root.relaxed]
    environment: root.nmcliEnvironment
    onDone: root.relaxed = ""
    onFailed: root.relaxed = ""
  }

  onPortalChanged: {
    // Signing in already, the browser is open on it.
    if (root.portal && root.relaxed === "") {
      portalNote.card = 0;
      portalNote.running = true;
    } else if (!root.portal) {
      Notifs.close(portalNote.card);
      portalNote.running = false;
    }
  }

  // Signing in happens in the browser, which says nothing to NetworkManager.
  Timer {
    id: recheck

    interval: 10000
    repeat: true
    running: root.portal || root.relaxed !== ""
    onTriggered: Networking.checkConnectivity()
  }

  // Every change NetworkManager makes, and whether it runs: "is running", "has started", "is stopped", "not running".
  Watcher {
    id: monitor

    // nmcli ignores SIGPIPE, so left by a crashed shell it would write to nobody for good: the reader takes it along as it goes, killed or not.
    command: ["bash", "-c", 'exec 3< <(exec setpriv --pdeathsig TERM nmcli monitor); nmcli=$!; trap \'kill "$nmcli" 2> /dev/null\' EXIT; trap exit PIPE TERM HUP; while IFS= read -r line <&3; do printf "%s\\n" "$line"; done']
    baseInterval: 2000
    // A machine without nmcli would fill the log; the backoff is enough.
    warn: false
    environment: root.nmcliEnvironment
    onLine: line => {
      if (/is running|has started/.test(line)) root.running = true;
      else if (/is stopped|not running|has stopped/.test(line)) root.running = false;
      settle.restart();
    }
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

    // The name last: -t escapes only its separator, so a name holding a newline runs on into lines that start with no UUID.
    command: ["nmcli", "-t", "-f", "UUID,TYPE,ACTIVE,STATE,NAME", "connection", "show"]
    environment: root.nmcliEnvironment
    stdout: StdioCollector {
      onStreamFinished: {
        const records = [];
        for (const line of text.replace(/\n$/, "").split("\n")) {
          if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:/.test(line) || records.length === 0) records.push(line);
          else records[records.length - 1] += `\n${line}`;
        }
        const vpns = [];
        for (const record of records) {
          const fields = root.fields(record);
          // A record cut short is no profile, and Qt 6.12 would leave its missing fields stale (TODO.md).
          if (fields.length < 5) continue;
          const [uuid, type, active, state, name] = fields;
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

  Deadline {
    process: vpnList
  }

  StateFile {
    name: "network.json"

    JsonAdapter {
      id: saved

      property string relaxed: ""
      property string relaxedFor: ""
    }
  }

  Component.onCompleted: vpnList.refresh()
}
