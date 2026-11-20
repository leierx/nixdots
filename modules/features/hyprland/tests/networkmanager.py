"""A NetworkManager for qs-test: devices, networks in the air, saved profiles and VPNs.

Behaves as NetworkManager 1.56 does for what the shell and nmcli use: activation goes
through Activating to Activated, or for a wrong password through NeedAuth to Failed with
the no-secrets reason; turning the radio off drops Wi-Fi; WireGuard gets a device while up.
qs-test drives it through the org.freedesktop.DBus.Mock methods below (`qst network`).
"""

import json
import time
import uuid as uuidlib

import dbus
import dbus.service
from gi.repository import GLib

import dbusmock
from dbusmock import MOCK_IFACE
from dbusmock.mockobject import DBusMockObject

BUS_NAME = "org.freedesktop.NetworkManager"
MAIN_OBJ = "/org/freedesktop"
MAIN_IFACE = "org.freedesktop.DBus.Mock.NetworkManager"
SYSTEM_BUS = True
IS_OBJECT_MANAGER = True

NM = "/org/freedesktop/NetworkManager"
NM_IFACE = "org.freedesktop.NetworkManager"
SETTINGS = "/org/freedesktop/NetworkManager/Settings"
SETTINGS_IFACE = "org.freedesktop.NetworkManager.Settings"
CONN_IFACE = "org.freedesktop.NetworkManager.Settings.Connection"
DEVICE_IFACE = "org.freedesktop.NetworkManager.Device"
WIRED_IFACE = "org.freedesktop.NetworkManager.Device.Wired"
WIRELESS_IFACE = "org.freedesktop.NetworkManager.Device.Wireless"
WIREGUARD_IFACE = "org.freedesktop.NetworkManager.Device.WireGuard"
AP_IFACE = "org.freedesktop.NetworkManager.AccessPoint"
ACTIVE_IFACE = "org.freedesktop.NetworkManager.Connection.Active"
VPN_IFACE = "org.freedesktop.NetworkManager.VPN.Connection"

# NMDeviceState, NMDeviceStateReason, NMActiveConnectionState(Reason)
UNAVAILABLE, DISCONNECTED, PREPARE, NEED_AUTH, ACTIVATED, DEACTIVATING, FAILED = 20, 30, 40, 60, 100, 110, 120
REASON_NONE, REASON_NO_SECRETS, REASON_SSID_NOT_FOUND, REASON_USER = 0, 7, 53, 39
AC_ACTIVATING, AC_ACTIVATED, AC_DEACTIVATING, AC_DEACTIVATED = 1, 2, 3, 4
AC_REASON_NONE, AC_REASON_USER, AC_REASON_DEVICE, AC_REASON_LOGIN_FAILED, AC_REASON_NO_SECRETS = 1, 2, 3, 10, 9
CARRIER = 0x10000
TYPES = {"ethernet": 1, "wifi": 2, "wireguard": 29}

# AP security flags: privacy; RSN pairwise and group CCMP with PSK, SAE or 802.1X.
SECURITY = {
    "open": (0, 0, 0),
    "wep": (1, 0, 0),
    "wpa": (1, 0x188, 0),
    "wpa2": (1, 0, 0x188),
    "wpa3": (1, 0, 0x488),
    "enterprise": (1, 0, 0x288),
}

state = {
    "devices": {},  # iface -> {path, type, carrier, speed, active, aps}
    "air": [],  # {ssid, bssid, strength, security, password, iface, path}
    "profiles": {},  # uuid -> {path, id, type, ssid, psk, behaviour, settings}
    "active": {},  # path -> {uuid, device}
    "delay": 400,
    "counter": 0,
}


def boottime_ms():
    return int(time.clock_gettime(time.CLOCK_BOOTTIME) * 1000)


def nextpath(kind):
    state["counter"] += 1
    return dbus.ObjectPath(f"{NM}/{kind}/{state['counter']}")


def obj(path):
    return dbusmock.get_object(path)


# The main object, which dbusmock registers only once load() has run.
main = {}


def mock():
    return main["object"]


# dbusmock's UpdateProperties cannot wrap an object path.
def update(path, iface, props):
    o = obj(path)
    o.props[iface].update(props)
    o.EmitSignal(dbus.PROPERTIES_IFACE, "PropertiesChanged", "sa{sv}as", [iface, dbus.Dictionary(props, signature="sv"), dbus.Array([], signature="s")])


def add_object(path, iface, props, methods):
    mock().AddObject(path, iface, props, methods)
    mock().object_manager_emit_added(path)


def remove_object(path):
    mock().object_manager_emit_removed(path)
    mock().RemoveObject(path)


def manager_props():
    m = obj(NM)
    return m.props[NM_IFACE]


# A property written over D-Bus (WirelessEnabled, a device's Autoconnect) acts as it does in NetworkManager.
_set = DBusMockObject.Set


@dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="ssv", out_signature="")
def _hooked_set(self, interface_name, property_name, value, *args, **kwargs):
    _set(self, interface_name, property_name, value, *args, **kwargs)
    if interface_name == NM_IFACE and property_name == "WirelessEnabled":
        GLib.idle_add(radio_changed)


DBusMockObject.Set = _hooked_set


def wifi_devices():
    return [d for d in state["devices"].values() if d["type"] == "wifi"]


def radio_on():
    props = manager_props()
    return bool(props["WirelessEnabled"]) and bool(props["WirelessHardwareEnabled"])


def radio_changed():
    for iface, dev in state["devices"].items():
        if dev["type"] != "wifi":
            continue
        if radio_on():
            set_device_state(dev, DISCONNECTED, REASON_NONE)
        else:
            if dev["active"]:
                drop_active(dev["active"], AC_REASON_DEVICE)
            set_device_state(dev, UNAVAILABLE, REASON_NONE)
        refresh_aps(iface)
    return False


def global_state():
    up = [a for a in state["active"].values() if a["state"] == AC_ACTIVATED]
    nm = obj(NM)
    value = dbus.UInt32(70 if up else 20)
    update(NM, NM_IFACE, {
        "State": value,
        "ActiveConnections": dbus.Array(list(state["active"].keys()), signature="o"),
        "PrimaryConnection": dbus.ObjectPath(next((p for p, a in state["active"].items() if a["state"] == AC_ACTIVATED and not a["vpn"]), "/")),
    })
    nm.EmitSignal(NM_IFACE, "StateChanged", "u", [value])


def set_device_state(dev, new, reason):
    path = dev["path"]
    old = obj(path).props[DEVICE_IFACE]["State"]
    update(path, DEVICE_IFACE, {"State": dbus.UInt32(new), "StateReason": dbus.Struct((dbus.UInt32(new), dbus.UInt32(reason)), signature="uu")})
    obj(path).EmitSignal(DEVICE_IFACE, "StateChanged", "uuu", [dbus.UInt32(new), old, dbus.UInt32(reason)])


# Settings ----------------------------------------------------------------------------------


def ssid_bytes(ssid):
    return dbus.Array([dbus.Byte(b) for b in ssid.encode()], signature="y")


def profile_settings(p):
    s = {
        "connection": {"id": p["id"], "uuid": p["uuid"], "type": {"wifi": "802-11-wireless", "ethernet": "802-3-ethernet"}.get(p["type"], p["type"]), "timestamp": dbus.UInt64(p.get("timestamp", 0)), "autoconnect": True},
        "ipv4": {"method": "auto"},
        "ipv6": {"method": "auto"},
    }
    if p["type"] == "wifi":
        s["802-11-wireless"] = {"ssid": ssid_bytes(p["ssid"]), "mode": "infrastructure"}
        if p.get("security", "open") != "open":
            s["802-11-wireless"]["security"] = "802-11-wireless-security"
            s["802-11-wireless-security"] = {"key-mgmt": {"wpa3": "sae", "enterprise": "wpa-eap"}.get(p["security"], "wpa-psk")}
    if p["type"] == "ethernet":
        s["802-3-ethernet"] = {}
        if p.get("iface"):
            s["connection"]["interface-name"] = p["iface"]
    if p["type"] == "wireguard":
        s["connection"]["interface-name"] = p["id"]
        s["wireguard"] = {}
    if p["type"] == "vpn":
        s["vpn"] = {"service-type": "org.freedesktop.NetworkManager.openvpn", "data": dbus.Dictionary({"remote": "vpn.example.org"}, signature="ss")}
    return dbus.Dictionary({k: dbus.Dictionary(v, signature="sv") for k, v in s.items()}, signature="sa{sv}")


def add_profile(kind, name, ssid="", psk="", security="open", behaviour="ok", iface="", uuid=None, timestamp=0):
    path = nextpath("Settings")
    uuid = uuid or str(uuidlib.uuid4())
    p = {"path": path, "uuid": uuid, "id": name, "type": kind, "ssid": ssid, "psk": psk, "security": security, "behaviour": behaviour, "iface": iface, "timestamp": timestamp}
    state["profiles"][uuid] = p
    methods = [
        ("GetSettings", "", "a{sa{sv}}", f"ret = self.nm_settings('{uuid}')"),
        ("GetSecrets", "s", "a{sa{sv}}", f"ret = self.nm_secrets('{uuid}', args[0])"),
        ("Update", "a{sa{sv}}", "", f"self.nm_update('{uuid}', args[0])"),
        ("UpdateUnsaved", "a{sa{sv}}", "", f"self.nm_update('{uuid}', args[0])"),
        ("Update2", "a{sa{sv}}ua{sv}", "a{sv}", f"self.nm_update('{uuid}', args[0]); ret = {{}}"),
        ("Delete", "", "", f"self.nm_delete('{uuid}')"),
        ("ClearSecrets", "", "", f"self.nm_clear('{uuid}')"),
        ("Save", "", "", ""),
    ]
    add_object(path, CONN_IFACE, {"Unsaved": False, "Flags": dbus.UInt32(0), "Filename": f"/etc/NetworkManager/system-connections/{name}.nmconnection"}, methods)
    o = obj(path)
    o.nm_settings = lambda u: profile_settings(state["profiles"][u])
    o.nm_secrets = lambda u, setting: secrets(state["profiles"][u], setting)
    o.nm_update = lambda u, s: update_profile(u, s)
    o.nm_delete = lambda u: delete_profile(u)
    o.nm_clear = lambda u: state["profiles"][u].update(psk="")
    connections = list(obj(SETTINGS).props[SETTINGS_IFACE]["Connections"]) + [path]
    update(SETTINGS, SETTINGS_IFACE, {"Connections": dbus.Array(connections, signature="o")})
    obj(SETTINGS).EmitSignal(SETTINGS_IFACE, "NewConnection", "o", [path])
    refresh_available()
    return p


def secrets(p, setting):
    if setting == "802-11-wireless-security" and p["psk"]:
        return dbus.Dictionary({setting: dbus.Dictionary({"psk": p["psk"]}, signature="sv")}, signature="sa{sv}")
    return dbus.Dictionary({}, signature="sa{sv}")


def update_profile(uuid, settings):
    p = state["profiles"][uuid]
    psk = settings.get("802-11-wireless-security", {}).get("psk")
    if psk is not None:
        p["psk"] = str(psk)
    name = settings.get("connection", {}).get("id")
    if name:
        p["id"] = str(name)
    o = obj(p["path"])
    o.EmitSignal(CONN_IFACE, "Updated", "", [])


def delete_profile(uuid):
    p = state["profiles"].pop(uuid, None)
    if not p:
        return
    for path, a in list(state["active"].items()):
        if a["uuid"] == uuid:
            drop_active(path, AC_REASON_USER)
    connections = [c for c in obj(SETTINGS).props[SETTINGS_IFACE]["Connections"] if c != p["path"]]
    update(SETTINGS, SETTINGS_IFACE, {"Connections": dbus.Array(connections, signature="o")})
    obj(p["path"]).EmitSignal(CONN_IFACE, "Removed", "", [])
    obj(SETTINGS).EmitSignal(SETTINGS_IFACE, "ConnectionRemoved", "o", [p["path"]])
    refresh_available()
    remove_object(p["path"])


def settings_add(settings):
    c = settings.get("connection", {})
    kind = {"802-11-wireless": "wifi", "802-3-ethernet": "ethernet"}.get(str(c.get("type", "")), str(c.get("type", "")))
    ssid = bytes(settings.get("802-11-wireless", {}).get("ssid", b"")).decode(errors="replace")
    psk = str(settings.get("802-11-wireless-security", {}).get("psk", ""))
    return add_profile(kind, str(c.get("id", ssid or kind)), ssid=ssid, psk=psk, security=security_of(ssid))["path"]


def security_of(ssid):
    return next((a["security"] for a in state["air"] if a["ssid"] == ssid), "wpa2")


# Profiles a device can take now: as NetworkManager's, a Wi-Fi one only while its network is in range.
def refresh_available():
    for iface, dev in state["devices"].items():
        if dev["type"] == "wifi":
            seen = {a["ssid"] for a in dev["aps"].values()}
            paths = [p["path"] for p in state["profiles"].values() if p["type"] == "wifi" and p["ssid"] in seen]
        elif dev["type"] == "ethernet":
            paths = [p["path"] for p in state["profiles"].values() if p["type"] == "ethernet" and p["iface"] in ("", iface)] if dev["carrier"] else []
        else:
            paths = []
        update(dev["path"], DEVICE_IFACE, {"AvailableConnections": dbus.Array(paths, signature="o")})


# Devices -----------------------------------------------------------------------------------


def add_device(iface, kind, carrier=True, speed=1000):
    path = nextpath("Devices")
    dev = {"path": path, "type": kind, "carrier": carrier, "speed": speed, "active": None, "aps": {}}
    state["devices"][iface] = dev
    on = kind != "wifi" or radio_on()
    props = {
        "Udi": f"/sys/devices/virtual/net/{iface}",
        "Path": "",
        "Interface": iface,
        "IpInterface": iface,
        "Driver": "qs-test",
        "DriverVersion": "",
        "FirmwareVersion": "",
        "Capabilities": dbus.UInt32(3),
        "State": dbus.UInt32(DISCONNECTED if on and (kind != "ethernet" or carrier) else UNAVAILABLE),
        "StateReason": dbus.Struct((dbus.UInt32(DISCONNECTED), dbus.UInt32(0)), signature="uu"),
        "ActiveConnection": dbus.ObjectPath("/"),
        "Ip4Config": dbus.ObjectPath("/"),
        "Dhcp4Config": dbus.ObjectPath("/"),
        "Ip6Config": dbus.ObjectPath("/"),
        "Dhcp6Config": dbus.ObjectPath("/"),
        "Managed": True,
        "Autoconnect": True,
        "FirmwareMissing": False,
        "NmPluginMissing": False,
        "DeviceType": dbus.UInt32(TYPES[kind]),
        "AvailableConnections": dbus.Array([], signature="o"),
        "PhysicalPortId": "",
        "Mtu": dbus.UInt32(1500),
        "Metered": dbus.UInt32(0),
        "LldpNeighbors": dbus.Array([], signature="a{sv}"),
        "Real": True,
        "Ip4Connectivity": dbus.UInt32(4),
        "Ip6Connectivity": dbus.UInt32(4),
        "InterfaceFlags": dbus.UInt32(0x1 | (CARRIER if carrier else 0)),
        "HwAddress": "52:54:00:%02x:%02x:%02x" % (state["counter"], len(iface), 7),
        "Ports": dbus.Array([], signature="o"),
    }
    methods = [
        ("Disconnect", "", "", f"self.nm_disconnect('{iface}')"),
        ("Delete", "", "", ""),
        ("Reapply", "a{sa{sv}}tu", "", ""),
        ("GetAppliedConnection", "u", "a{sa{sv}}t", "ret = ({}, 0)"),
    ]
    add_object(path, DEVICE_IFACE, props, methods)
    o = obj(path)
    o.nm_disconnect = lambda i: disconnect(i)
    if kind == "ethernet":
        o.AddProperties(WIRED_IFACE, {"HwAddress": props["HwAddress"], "PermHwAddress": props["HwAddress"], "Speed": dbus.UInt32(speed if carrier else 0), "S390Subchannels": dbus.Array([], signature="s"), "Carrier": carrier})
    elif kind == "wifi":
        o.AddProperties(WIRELESS_IFACE, {
            "HwAddress": props["HwAddress"],
            "PermHwAddress": props["HwAddress"],
            "Mode": dbus.UInt32(2),
            "Bitrate": dbus.UInt32(0),
            "AccessPoints": dbus.Array([], signature="o"),
            "ActiveAccessPoint": dbus.ObjectPath("/"),
            "WirelessCapabilities": dbus.UInt32(0x7FF),
            "LastScan": dbus.Int64(boottime_ms()),
        })
        o.AddMethods(WIRELESS_IFACE, [
            ("GetAccessPoints", "", "ao", f"ret = self.nm_aps('{iface}')"),
            ("GetAllAccessPoints", "", "ao", f"ret = self.nm_aps('{iface}')"),
            ("RequestScan", "a{sv}", "", f"self.nm_scan('{iface}')"),
        ])
        o.nm_aps = lambda i: dbus.Array(list(state["devices"][i]["aps"].keys()), signature="o")
        o.nm_scan = lambda i: update(state["devices"][i]["path"], WIRELESS_IFACE, {"LastScan": dbus.Int64(boottime_ms())})
    elif kind == "wireguard":
        o.AddProperties(WIREGUARD_IFACE, {"PublicKey": dbus.Array([], signature="y"), "ListenPort": dbus.UInt16(51820), "FwMark": dbus.UInt32(0)})
    devices = [d["path"] for d in state["devices"].values()]
    update(NM, NM_IFACE, {"Devices": dbus.Array(devices, signature="o"), "AllDevices": dbus.Array(devices, signature="o")})
    obj(NM).EmitSignal(NM_IFACE, "DeviceAdded", "o", [path])
    if kind == "wifi":
        refresh_aps(iface)
    refresh_available()
    return dev


def remove_device(iface):
    dev = state["devices"].get(iface)
    if not dev:
        return
    if dev["active"]:
        drop_active(dev["active"], AC_REASON_DEVICE)
    for ap in list(dev["aps"]):
        remove_object(ap)
    del state["devices"][iface]
    devices = [d["path"] for d in state["devices"].values()]
    update(NM, NM_IFACE, {"Devices": dbus.Array(devices, signature="o"), "AllDevices": dbus.Array(devices, signature="o")})
    obj(NM).EmitSignal(NM_IFACE, "DeviceRemoved", "o", [dev["path"]])
    remove_object(dev["path"])


# Each Wi-Fi device sees the networks in the air while its radio is on, an access point per network and BSSID.
def refresh_aps(iface):
    dev = state["devices"][iface]
    wanted = {a["bssid"]: a for a in state["air"] if radio_on() and a["iface"] in ("", iface)}
    have = {o: a for o, a in dev["aps"].items()}
    for path, a in have.items():
        if a["bssid"] not in wanted:
            del dev["aps"][path]
            obj(dev["path"]).EmitSignal(WIRELESS_IFACE, "AccessPointRemoved", "o", [path])
            remove_object(path)
            if dev["active"] and state["active"][dev["active"]].get("ap") == path:
                fail(dev, dev["active"], REASON_SSID_NOT_FOUND)
    known = {a["bssid"] for a in dev["aps"].values()}
    for bssid, a in wanted.items():
        if bssid in known:
            path = next(p for p, x in dev["aps"].items() if x["bssid"] == bssid)
            update(path, AP_IFACE, {"Strength": dbus.Byte(a["strength"])})
            continue
        path = nextpath("AccessPoint")
        flags, wpa, rsn = SECURITY[a["security"]]
        add_object(path, AP_IFACE, {
            "Flags": dbus.UInt32(flags),
            "WpaFlags": dbus.UInt32(wpa),
            "RsnFlags": dbus.UInt32(rsn),
            "Ssid": ssid_bytes(a["ssid"]),
            "Frequency": dbus.UInt32(2437),
            "HwAddress": a["bssid"],
            "Mode": dbus.UInt32(2),
            "MaxBitrate": dbus.UInt32(54000),
            "Bandwidth": dbus.UInt32(20),
            "Strength": dbus.Byte(a["strength"]),
            "LastSeen": dbus.Int32(int(time.clock_gettime(time.CLOCK_BOOTTIME))),
        }, [])
        dev["aps"][path] = dict(a)
        obj(dev["path"]).EmitSignal(WIRELESS_IFACE, "AccessPointAdded", "o", [path])
    update(dev["path"], WIRELESS_IFACE, {"AccessPoints": dbus.Array(list(dev["aps"].keys()), signature="o"), "LastScan": dbus.Int64(boottime_ms())})
    refresh_available()


# Activation --------------------------------------------------------------------------------


def activate(conn_path, dev_path, specific):
    p = next((p for p in state["profiles"].values() if p["path"] == conn_path), None)
    if not p:
        raise dbus.exceptions.DBusException("no such connection", name="org.freedesktop.NetworkManager.UnknownConnection")
    if p["type"] in ("wireguard", "vpn"):
        return activate_vpn(p)
    iface = next((i for i, d in state["devices"].items() if d["path"] == dev_path), None)
    if iface is None:
        iface = next((i for i, d in state["devices"].items() if d["type"] == p["type"]), None)
    if iface is None:
        raise dbus.exceptions.DBusException("no suitable device", name="org.freedesktop.NetworkManager.UnknownDevice")
    dev = state["devices"][iface]
    ap = "/"
    if p["type"] == "wifi":
        if not radio_on():
            raise dbus.exceptions.DBusException("Wi-Fi is off", name="org.freedesktop.NetworkManager.UnmanagedDevice")
        ap = next((path for path, a in sorted(dev["aps"].items(), key=lambda x: -x[1]["strength"]) if a["ssid"] == p["ssid"]), None)
        if ap is None:
            raise dbus.exceptions.DBusException(f"no network {p['ssid']}", name="org.freedesktop.NetworkManager.UnknownConnection")
    if dev["active"]:
        drop_active(dev["active"], AC_REASON_USER)
    path = new_active(p, [dev["path"]], ap)
    dev["active"] = path
    state["active"][path]["device"] = iface
    update(dev["path"], DEVICE_IFACE, {"ActiveConnection": path})
    set_device_state(dev, PREPARE, REASON_NONE)
    GLib.timeout_add(state["delay"], finish, path)
    return path


def finish(path):
    a = state["active"].get(path)
    if not a or a["state"] != AC_ACTIVATING:
        return False
    p = state["profiles"].get(a["uuid"])
    dev = state["devices"].get(a.get("device")) if a.get("device") else None
    if p is None:
        drop_active(path, AC_REASON_USER)
        return False
    if p["type"] == "wifi":
        air = next((x for x in state["air"] if x["ssid"] == p["ssid"]), None)
        if air and air["security"] != "open" and (air["security"] == "enterprise" or air["password"] != p["psk"]):
            set_device_state(dev, NEED_AUTH, REASON_NONE)
            fail(dev, path, REASON_NO_SECRETS)
            return False
    if p["type"] in ("wireguard", "vpn") and p["behaviour"] != "ok" and not (p["behaviour"] == "secrets" and p.pop("given", False)):
        reason = AC_REASON_NO_SECRETS if p["behaviour"] == "secrets" else AC_REASON_LOGIN_FAILED
        drop_active(path, reason)
        return False
    p["timestamp"] = int(time.time())
    a["state"] = AC_ACTIVATED
    update(path, ACTIVE_IFACE, {"State": dbus.UInt32(AC_ACTIVATED)})
    obj(path).EmitSignal(ACTIVE_IFACE, "StateChanged", "uu", [dbus.UInt32(AC_ACTIVATED), dbus.UInt32(AC_REASON_NONE)])
    if a["vpn"]:
        update(path, VPN_IFACE, {"VpnState": dbus.UInt32(5)})
        obj(path).EmitSignal(VPN_IFACE, "VpnStateChanged", "uu", [dbus.UInt32(5), dbus.UInt32(1)])
    if dev:
        if p["type"] == "wifi":
            update(dev["path"], WIRELESS_IFACE, {"ActiveAccessPoint": dbus.ObjectPath(a["ap"])})
        set_device_state(dev, ACTIVATED, REASON_NONE)
    global_state()
    return False


def fail(dev, path, reason):
    set_device_state(dev, FAILED, reason)
    drop_active(path, AC_REASON_DEVICE)
    set_device_state(dev, DISCONNECTED, reason)


def new_active(p, devices, ap):
    path = nextpath("ActiveConnection")
    vpn = p["type"] == "vpn"
    add_object(path, ACTIVE_IFACE, {
        "Connection": dbus.ObjectPath(p["path"]),
        "SpecificObject": dbus.ObjectPath(ap),
        "Id": p["id"],
        "Uuid": p["uuid"],
        "Type": {"wifi": "802-11-wireless", "ethernet": "802-3-ethernet"}.get(p["type"], p["type"]),
        "Devices": dbus.Array(devices, signature="o"),
        "State": dbus.UInt32(AC_ACTIVATING),
        "StateFlags": dbus.UInt32(0),
        "Default": False,
        "Ip4Config": dbus.ObjectPath("/"),
        "Dhcp4Config": dbus.ObjectPath("/"),
        "Default6": False,
        "Ip6Config": dbus.ObjectPath("/"),
        "Dhcp6Config": dbus.ObjectPath("/"),
        "Vpn": vpn,
        "Master": dbus.ObjectPath("/"),
        "Controller": dbus.ObjectPath("/"),
    }, [])
    if vpn:
        obj(path).AddProperties(VPN_IFACE, {"VpnState": dbus.UInt32(3), "Banner": ""})
    state["active"][path] = {"uuid": p["uuid"], "state": AC_ACTIVATING, "ap": ap, "vpn": vpn, "device": None}
    global_state()
    return path


def activate_vpn(p):
    for path, a in state["active"].items():
        if a["uuid"] == p["uuid"]:
            return dbus.ObjectPath(path)
    devices = []
    if p["type"] == "wireguard":
        dev = state["devices"].get(p["id"]) or add_device(p["id"], "wireguard")
        devices = [dev["path"]]
    else:
        base = next((d for d in state["devices"].values() if d["active"]), None)
        devices = [base["path"]] if base else []
    path = new_active(p, devices, "/")
    if p["type"] == "wireguard":
        dev = state["devices"][p["id"]]
        dev["active"] = path
        state["active"][path]["device"] = p["id"]
        update(dev["path"], DEVICE_IFACE, {"ActiveConnection": path})
        set_device_state(dev, PREPARE, REASON_NONE)
    GLib.timeout_add(state["delay"], finish, path)
    return path


def drop_active(path, reason):
    a = state["active"].pop(path, None)
    if not a:
        return
    update(path, ACTIVE_IFACE, {"State": dbus.UInt32(AC_DEACTIVATED)})
    obj(path).EmitSignal(ACTIVE_IFACE, "StateChanged", "uu", [dbus.UInt32(AC_DEACTIVATED), dbus.UInt32(reason)])
    if a["vpn"]:
        obj(path).EmitSignal(VPN_IFACE, "VpnStateChanged", "uu", [dbus.UInt32(7 if reason == AC_REASON_USER else 6), dbus.UInt32(reason)])
    iface = a.get("device")
    dev = state["devices"].get(iface) if iface else None
    if dev and dev["active"] == path:
        dev["active"] = None
        update(dev["path"], DEVICE_IFACE, {"ActiveConnection": dbus.ObjectPath("/")})
        if dev["type"] == "wifi":
            update(dev["path"], WIRELESS_IFACE, {"ActiveAccessPoint": dbus.ObjectPath("/")})
        p = state["profiles"].get(a["uuid"])
        if dev["type"] == "wireguard":
            remove_device(iface)
        elif obj(dev["path"]).props[DEVICE_IFACE]["State"] not in (FAILED, UNAVAILABLE):
            set_device_state(dev, DISCONNECTED, REASON_USER if reason == AC_REASON_USER else REASON_NONE)
    global_state()
    GLib.timeout_add(50, lambda: (remove_object(path), False)[1])


def deactivate(path):
    if str(path) not in state["active"]:
        raise dbus.exceptions.DBusException("not active", name="org.freedesktop.NetworkManager.ConnectionNotActive")
    drop_active(str(path), AC_REASON_USER)


def disconnect(iface):
    dev = state["devices"][iface]
    if not dev["active"]:
        raise dbus.exceptions.DBusException("not active", name="org.freedesktop.NetworkManager.Device.NotActive")
    drop_active(dev["active"], AC_REASON_USER)


def add_and_activate(settings, dev_path, specific):
    ap = state["devices"].get(next((i for i, d in state["devices"].items() if d["path"] == dev_path), ""), {}).get("aps", {}).get(str(specific))
    ssid = ap["ssid"] if ap else bytes(settings.get("802-11-wireless", {}).get("ssid", b"")).decode(errors="replace")
    psk = str(settings.get("802-11-wireless-security", {}).get("psk", ""))
    p = add_profile("wifi", ssid, ssid=ssid, psk=psk, security=security_of(ssid))
    return (dbus.ObjectPath(p["path"]), activate(p["path"], dev_path, specific))


def dump():
    return json.dumps({
        "wireless": bool(manager_props()["WirelessEnabled"]),
        "hardware": bool(manager_props()["WirelessHardwareEnabled"]),
        "connectivity": int(manager_props()["Connectivity"]),
        "devices": [{"iface": i, "type": d["type"], "carrier": d["carrier"], "speed": d["speed"]} for i, d in state["devices"].items() if d["type"] != "wireguard"],
        "air": [{k: a[k] for k in ("ssid", "bssid", "strength", "security", "password", "iface")} for a in state["air"]],
        "profiles": [{k: p[k] for k in ("uuid", "id", "type", "ssid", "psk", "security", "behaviour", "iface", "timestamp")} for p in state["profiles"].values()],
        "active": [a["uuid"] for a in state["active"].values() if a["state"] == AC_ACTIVATED],
        "delay": state["delay"],
    })


def load(mock_obj, parameters):
    main["object"] = mock_obj
    saved = json.loads(parameters.get("state", "{}"))
    mock_obj.AddObject(NM, NM_IFACE, {
        "Devices": dbus.Array([], signature="o"),
        "AllDevices": dbus.Array([], signature="o"),
        "Checkpoints": dbus.Array([], signature="o"),
        "NetworkingEnabled": True,
        "WirelessEnabled": saved.get("wireless", True),
        "WirelessHardwareEnabled": saved.get("hardware", True),
        "WwanEnabled": False,
        "WwanHardwareEnabled": False,
        "WimaxEnabled": False,
        "WimaxHardwareEnabled": False,
        "RadioFlags": dbus.UInt32(1),
        "ActiveConnections": dbus.Array([], signature="o"),
        "PrimaryConnection": dbus.ObjectPath("/"),
        "PrimaryConnectionType": "",
        "Metered": dbus.UInt32(4),
        "ActivatingConnection": dbus.ObjectPath("/"),
        "Startup": False,
        "Version": "1.56.0",
        "VersionInfo": dbus.Array([dbus.UInt32(0x013800)], signature="u"),
        "Capabilities": dbus.Array([], signature="u"),
        "State": dbus.UInt32(20),
        "Connectivity": dbus.UInt32(saved.get("connectivity", 4)),
        "ConnectivityCheckAvailable": True,
        "ConnectivityCheckEnabled": True,
        "ConnectivityCheckUri": "http://nmcheck.gnome.org/check_network_status.txt",
        "GlobalDnsConfiguration": dbus.Dictionary({}, signature="sv"),
    }, [
        ("GetDevices", "", "ao", f"ret = self.Get('{NM_IFACE}', 'Devices')"),
        ("GetAllDevices", "", "ao", f"ret = self.Get('{NM_IFACE}', 'AllDevices')"),
        ("GetPermissions", "", "a{ss}", "ret = {p: 'yes' for p in ['network-control', 'enable-disable-wifi', 'enable-disable-network', 'settings.modify.system', 'settings.modify.own', 'wifi.scan']} and {'org.freedesktop.NetworkManager.' + p: 'yes' for p in ['network-control', 'enable-disable-wifi', 'enable-disable-network', 'settings.modify.system', 'settings.modify.own', 'wifi.scan']}"),
        ("GetLogging", "", "ss", "ret = ('INFO', '')"),
        ("state", "", "u", f"ret = self.Get('{NM_IFACE}', 'State')"),
        ("CheckConnectivity", "", "u", f"ret = self.Get('{NM_IFACE}', 'Connectivity')"),
        ("ActivateConnection", "ooo", "o", "ret = self.nm_activate(args[0], args[1], args[2])"),
        ("AddAndActivateConnection", "a{sa{sv}}oo", "oo", "ret = self.nm_add_and_activate(args[0], args[1], args[2])"),
        ("AddAndActivateConnection2", "a{sa{sv}}ooa{sv}", "ooa{sv}", "ret = self.nm_add_and_activate(args[0], args[1], args[2]) + ({},)"),
        ("DeactivateConnection", "o", "", "self.nm_deactivate(args[0])"),
        ("Enable", "b", "", ""),
        ("Reload", "u", "", ""),
    ])
    mock_obj.object_manager_emit_added(NM)
    nm = obj(NM)
    nm.nm_activate = activate
    nm.nm_add_and_activate = add_and_activate
    nm.nm_deactivate = deactivate

    mock_obj.AddObject(SETTINGS, SETTINGS_IFACE, {"Hostname": "qs-test", "CanModify": True, "Connections": dbus.Array([], signature="o")}, [
        ("ListConnections", "", "ao", f"ret = self.Get('{SETTINGS_IFACE}', 'Connections')"),
        ("GetConnectionByUuid", "s", "o", "ret = self.nm_by_uuid(args[0])"),
        ("AddConnection", "a{sa{sv}}", "o", "ret = self.nm_add(args[0])"),
        ("AddConnectionUnsaved", "a{sa{sv}}", "o", "ret = self.nm_add(args[0])"),
        ("SaveHostname", "s", "", ""),
        ("ReloadConnections", "", "b", "ret = True"),
    ])
    mock_obj.object_manager_emit_added(SETTINGS)
    settings = obj(SETTINGS)
    settings.nm_by_uuid = lambda u: dbus.ObjectPath(state["profiles"][u]["path"])
    settings.nm_add = settings_add

    mock_obj.AddObject(f"{NM}/AgentManager", "org.freedesktop.NetworkManager.AgentManager", {}, [
        ("Register", "s", "", ""),
        ("RegisterWithCapabilities", "su", "", ""),
        ("Unregister", "", "", ""),
    ])
    mock_obj.object_manager_emit_added(f"{NM}/AgentManager")

    state["delay"] = saved.get("delay", 400)
    for a in saved.get("air", []):
        state["air"].append(a)
    for d in saved.get("devices", []):
        add_device(d["iface"], d["type"], d["carrier"], d["speed"])
    for p in saved.get("profiles", []):
        add_profile(p["type"], p["id"], ssid=p["ssid"], psk=p["psk"], security=p["security"], behaviour=p["behaviour"], iface=p["iface"], uuid=p["uuid"], timestamp=p["timestamp"])
    # As NetworkManager assumes what was up when it started again.
    for uuid in saved.get("active", []):
        p = state["profiles"].get(uuid)
        if p:
            try:
                activate(p["path"], "/", "/")
            except dbus.exceptions.DBusException:
                pass
    global_state()


# Driven by qs-test ---------------------------------------------------------------------


@dbus.service.method(MOCK_IFACE, in_signature="ssbu", out_signature="")
def AddDevice(self, iface, kind, carrier, speed):
    add_device(str(iface), str(kind), bool(carrier), int(speed))


@dbus.service.method(MOCK_IFACE, in_signature="s", out_signature="")
def RemoveDevice(self, iface):
    remove_device(str(iface))


@dbus.service.method(MOCK_IFACE, in_signature="sb", out_signature="")
def SetCarrier(self, iface, carrier):
    dev = state["devices"][str(iface)]
    dev["carrier"] = bool(carrier)
    update(dev["path"], DEVICE_IFACE, {"InterfaceFlags": dbus.UInt32(0x1 | (CARRIER if carrier else 0))})
    update(dev["path"], WIRED_IFACE, {"Carrier": bool(carrier), "Speed": dbus.UInt32(dev["speed"] if carrier else 0)})
    if not carrier and dev["active"]:
        drop_active(dev["active"], AC_REASON_DEVICE)
    set_device_state(dev, DISCONNECTED if carrier else UNAVAILABLE, REASON_NONE)
    refresh_available()


@dbus.service.method(MOCK_IFACE, in_signature="sysss", out_signature="")
def AddNetwork(self, ssid, strength, security, password, iface):
    count = sum(1 for a in state["air"] if a["ssid"] == str(ssid))
    bssid = "02:%02x:%02x:%02x:%02x:%02x" % ((len(state["air"]) >> 24) & 255, (len(state["air"]) >> 16) & 255, (len(state["air"]) >> 8) & 255, len(state["air"]) & 255, count)
    state["air"].append({"ssid": str(ssid), "bssid": bssid, "strength": int(strength), "security": str(security), "password": str(password), "iface": str(iface)})
    for i in [i for i, d in state["devices"].items() if d["type"] == "wifi"]:
        refresh_aps(i)


@dbus.service.method(MOCK_IFACE, in_signature="a(sysss)", out_signature="")
def AddNetworks(self, networks):
    for ssid, strength, security, password, iface in networks:
        state["air"].append({"ssid": str(ssid), "bssid": "02:%02x:%02x:%02x:%02x:00" % ((len(state["air"]) >> 24) & 255, (len(state["air"]) >> 16) & 255, (len(state["air"]) >> 8) & 255, len(state["air"]) & 255), "strength": int(strength), "security": str(security), "password": str(password), "iface": str(iface)})
    for i in [i for i, d in state["devices"].items() if d["type"] == "wifi"]:
        refresh_aps(i)


@dbus.service.method(MOCK_IFACE, in_signature="s", out_signature="")
def RemoveNetwork(self, ssid):
    state["air"] = [a for a in state["air"] if a["ssid"] != str(ssid)]
    for i in [i for i, d in state["devices"].items() if d["type"] == "wifi"]:
        refresh_aps(i)


@dbus.service.method(MOCK_IFACE, in_signature="", out_signature="")
def ClearNetworks(self):
    state["air"] = []
    for i in [i for i, d in state["devices"].items() if d["type"] == "wifi"]:
        refresh_aps(i)


@dbus.service.method(MOCK_IFACE, in_signature="sy", out_signature="")
def SetStrength(self, ssid, strength):
    for a in state["air"]:
        if a["ssid"] == str(ssid):
            a["strength"] = int(strength)
    for i in [i for i, d in state["devices"].items() if d["type"] == "wifi"]:
        refresh_aps(i)


@dbus.service.method(MOCK_IFACE, in_signature="ssss", out_signature="s")
def AddProfile(self, kind, name, ssid, psk):
    return add_profile(str(kind), str(name), ssid=str(ssid), psk=str(psk), security=security_of(str(ssid)) if kind == "wifi" else "open", timestamp=int(time.time()))["uuid"]


@dbus.service.method(MOCK_IFACE, in_signature="ss", out_signature="")
def SetBehaviour(self, name, behaviour):
    for p in state["profiles"].values():
        if p["id"] == str(name):
            p["behaviour"] = str(behaviour)


# As `nmcli connection up` asks, which in the session cannot run itself: libnm will not register its secret agent with a NetworkManager not run by root.
@dbus.service.method(MOCK_IFACE, in_signature="sb", out_signature="")
def Up(self, name, secrets):
    p = next((p for p in state["profiles"].values() if str(name) in (p["id"], p["uuid"])), None)
    if not p:
        raise dbus.exceptions.DBusException(f"no profile {name}", name="org.freedesktop.NetworkManager.UnknownConnection")
    p["given"] = bool(secrets)
    activate(p["path"], "/", "/")


@dbus.service.method(MOCK_IFACE, in_signature="u", out_signature="")
def SetConnectivity(self, connectivity):
    update(NM, NM_IFACE, {"Connectivity": dbus.UInt32(connectivity)})


@dbus.service.method(MOCK_IFACE, in_signature="b", out_signature="")
def SetHardwareSwitch(self, on):
    update(NM, NM_IFACE, {"WirelessHardwareEnabled": bool(on)})
    radio_changed()


@dbus.service.method(MOCK_IFACE, in_signature="u", out_signature="")
def SetDelay(self, ms):
    state["delay"] = int(ms)


@dbus.service.method(MOCK_IFACE, in_signature="", out_signature="s")
def Dump(self):
    return dump()


# Many at once, and names nothing has to quote: a JSON list of [ssid, strength, security, password].
@dbus.service.method(MOCK_IFACE, in_signature="s", out_signature="")
def AddNetworksJson(self, networks):
    for ssid, strength, security, password in json.loads(str(networks)):
        n = len(state["air"])
        state["air"].append({"ssid": ssid, "bssid": "02:%02x:%02x:%02x:%02x:00" % ((n >> 24) & 255, (n >> 16) & 255, (n >> 8) & 255, n & 255), "strength": int(strength), "security": security, "password": password, "iface": ""})
    for i in [i for i, d in state["devices"].items() if d["type"] == "wifi"]:
        refresh_aps(i)
