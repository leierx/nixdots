"""UPower for qs-test: dbusmock's upower template, with a laptop battery set in one call.

qs-test drives it through SetBattery below (`qst battery`).
"""

import dbus

from dbusmock import mockobject
from dbusmock.templates.upower import *  # noqa: F401,F403
from dbusmock.templates import upower

# UPower's device states: charging, discharging, empty, fully charged, pending charge
STATES = {"charging": 1, "discharging": 2, "empty": 3, "full": 4, "pending": 5}


@dbus.service.method(upower.MOCK_IFACE, in_signature="dsx", out_signature="")
def SetBattery(self, percentage, state, seconds):
    display = mockobject.objects["/org/freedesktop/UPower/devices/DisplayDevice"]
    present = percentage >= 0
    code = STATES.get(str(state), 2)
    props = {
        "Type": dbus.UInt32(2 if present else 0),
        "PowerSupply": dbus.Boolean(present),
        "IsPresent": dbus.Boolean(present),
        "State": dbus.UInt32(code if present else 0),
        "Percentage": dbus.Double(max(0.0, percentage)),
        "TimeToEmpty": dbus.Int64(seconds if code == 2 else 0),
        "TimeToFull": dbus.Int64(seconds if code == 1 else 0),
        "Energy": dbus.Double(max(0.0, percentage) / 2),
        "EnergyFull": dbus.Double(50.0),
        "EnergyRate": dbus.Double(10.0),
    }
    display.props[upower.DEVICE_IFACE].update(props)
    display.EmitSignal(dbus.PROPERTIES_IFACE, "PropertiesChanged", "sa{sv}as", [upower.DEVICE_IFACE, dbus.Dictionary(props, signature="sv"), dbus.Array([], signature="s")])
    main = mockobject.objects["/org/freedesktop/UPower"]
    on_battery = dbus.Boolean(present and code in (2, 3))
    main.props[upower.MAIN_IFACE]["OnBattery"] = on_battery
    main.EmitSignal(dbus.PROPERTIES_IFACE, "PropertiesChanged", "sa{sv}as", [upower.MAIN_IFACE, dbus.Dictionary({"OnBattery": on_battery}, signature="sv"), dbus.Array([], signature="s")])


_load = upower.load


# The display device as UPower 1.90 fills it in, which Quickshell reads whole.
def load(mock, parameters):
    _load(mock, parameters)
    display = mockobject.objects["/org/freedesktop/UPower/devices/DisplayDevice"]
    display.props[upower.DEVICE_IFACE].update({
        "NativePath": dbus.String(""),
        "Model": dbus.String(""),
        "Vendor": dbus.String(""),
        "Capacity": dbus.Double(100.0),
        "PowerSupply": dbus.Boolean(False),
    })
