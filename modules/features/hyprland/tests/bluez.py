"""BlueZ for qs-test: dbusmock's bluez5 template, with devices that look like real ones.

A device has an icon, a battery and a way of pairing: "ok" pairs without a code, "pin" wants
one (which nothing here can answer, as in the shell), "fail" refuses to connect.
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
    if BEHAVIOUR.get(device.path) == "fail":
        raise dbus.exceptions.DBusException("Page Timeout", name="org.bluez.Error.Failed")
    bluez5.Connect(device)


@dbus.service.method(bluez5.BLUEZ_MOCK_IFACE, in_signature="sssssbbi", out_signature="s")
def AddFullDevice(self, adapter, address, name, icon, behaviour, paired, connected, battery):
    path = bluez5.AddDevice(self, adapter, address, name)
    device = mockobject.objects[path]
    BEHAVIOUR[path] = str(behaviour)
    props = {"Icon": dbus.String(icon)}
    if not name:
        props.update({"Name": dbus.String(""), "Alias": dbus.String(address.replace(":", "-"))})
    device.props[bluez5.DEVICE_IFACE].update(props)
    device.EmitSignal(dbus.PROPERTIES_IFACE, "PropertiesChanged", "sa{sv}as", [bluez5.DEVICE_IFACE, dbus.Dictionary(props, signature="sv"), dbus.Array([], signature="s")])
    device.AddMethods(bluez5.DEVICE_IFACE, [("Pair", "", "", pair), ("Connect", "", "", connect)])
    if paired:
        bluez5.PairDevice(self, adapter, address)
    if connected:
        bluez5.ConnectDevice(self, adapter, address)
        # Which the stock Disconnect reads rather than the property.
        device.connected = True
    if battery >= 0:
        device.AddProperties("org.bluez.Battery1", {"Percentage": dbus.Byte(battery)})
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
