"""BlueZ for qs-test: dbusmock's bluez5 template, with devices that look like real ones.

A device has an icon, a battery and a way of pairing: "ok" pairs without a code, "pin" wants
one (which nothing here can answer, as in the shell), "fail" refuses to connect, "crowded" refuses
as another device turns up nearby.
qs-test drives it through the org.bluez.Mock methods below (`qst bluetooth`).
"""

import dbus

from dbusmock import mockobject
from dbusmock.templates.bluez5 import *  # noqa: F401,F403
from dbusmock.templates import bluez5

BEHAVIOUR = {}


def pair(device):
    behaviour = BEHAVIOUR.get(device.path, "ok")
    if behaviour == "pin":
        raise dbus.exceptions.DBusException("Authentication Failed", name="org.bluez.Error.AuthenticationFailed")
    bluez5.Pair(device)


def connect(device):
    behaviour = BEHAVIOUR.get(device.path)
    if behaviour == "crowded":
        # Announced before the error goes back, as discovery finds one while a connect is under way.
        bluez5.AddDevice(mockobject.objects["/"], device.path.split("/")[3], "11:22:33:44:55:EE", "Soundcore 2")
    if behaviour in ("fail", "crowded"):
        raise dbus.exceptions.DBusException("Page Timeout", name="org.bluez.Error.Failed")
    bluez5.Connect(device)


@dbus.service.method(bluez5.BLUEZ_MOCK_IFACE, in_signature="sssssbbi", out_signature="s")
def AddFullDevice(self, adapter, address, name, icon, behaviour, paired, connected, battery):
    adapter_path = f"/org/bluez/{adapter}"
    if adapter_path not in mockobject.objects:
        raise dbus.exceptions.DBusException(f"Adapter {adapter} does not exist", name=bluez5.BLUEZ_MOCK_IFACE + ".Error")
    path = f"{adapter_path}/dev_" + address.replace(":", "_").upper()
    if path in mockobject.objects:
        raise dbus.exceptions.DBusException(f"Device {address} already exists on adapter {adapter}", name=bluez5.BLUEZ_MOCK_IFACE + ".Error")
    BEHAVIOUR[path] = str(behaviour)
    alias = str(name) if name else str(address).replace(":", "-")
    props = {
        "UUIDs": dbus.Array([], signature="s"),
        "Blocked": dbus.Boolean(False),
        "Connected": dbus.Boolean(bool(connected)),
        "LegacyPairing": dbus.Boolean(False),
        "Paired": dbus.Boolean(bool(paired)),
        "Trusted": dbus.Boolean(False),
        "RSSI": dbus.Int16(-79),
        "Adapter": dbus.ObjectPath(adapter_path),
        "Address": dbus.String(address),
        "Alias": dbus.String(alias),
        "Name": dbus.String(name),
        "Icon": dbus.String(icon),
        "Class": dbus.UInt32(0),
        "Modalias": dbus.String(""),
    }
    self.AddObject(path, bluez5.DEVICE_IFACE, props, [
        ("CancelPairing", "", "", ""),
        ("Connect", "", "", connect),
        ("ConnectProfile", "s", "", ""),
        ("Disconnect", "", "", bluez5.Disconnect),
        ("DisconnectProfile", "s", "", ""),
        ("Pair", "", "", pair),
    ])
    device = mockobject.objects[path]
    device.paired = bool(paired)
    device.connected = bool(connected)
    if battery >= 0:
        device.AddProperties("org.bluez.Battery1", {"Percentage": dbus.Byte(battery)})
    # One InterfacesAdded with the final state avoids a PropertiesChanged race before clients add a match rule.
    self.object_manager_emit_added(path)
    return path


@dbus.service.method(bluez5.BLUEZ_MOCK_IFACE, in_signature="ss", out_signature="")
def RemoveFullDevice(self, adapter, address):
    path = f"/org/bluez/{adapter}/dev_" + address.replace(":", "_").upper()
    BEHAVIOUR.pop(path, None)
    bluez5.RemoveDevice(mockobject.objects[f"/org/bluez/{adapter}"], path)


# The stock template's discovery needs a filter set first; BlueZ's does not.
def discovery(adapter, on):
    adapter.props[bluez5.ADAPTER_IFACE]["Discovering"] = dbus.Boolean(on)
    adapter.EmitSignal(dbus.PROPERTIES_IFACE, "PropertiesChanged", "sa{sv}as", [bluez5.ADAPTER_IFACE, dbus.Dictionary({"Discovering": dbus.Boolean(on)}, signature="sv"), dbus.Array([], signature="s")])


@dbus.service.method(bluez5.BLUEZ_MOCK_IFACE, in_signature="ss", out_signature="s")
def AddAdapter(self, device_name, system_name):
    path = bluez5.AddAdapter(self, device_name, system_name)
    adapter = mockobject.objects[path]
    adapter.AddMethods(bluez5.ADAPTER_IFACE, [
        ("StartDiscovery", "", "", lambda adapter: discovery(adapter, True)),
        ("StopDiscovery", "", "", lambda adapter: discovery(adapter, False)),
    ])
    return path
