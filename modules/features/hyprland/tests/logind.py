"""logind for qs-test: only what the shell asks it, whether the firmware takes a reboot into its setup.

`firmware` in the parameters is the answer, "yes" unless set.
"""

BUS_NAME = "org.freedesktop.login1"
MAIN_OBJ = "/org/freedesktop/login1"
MAIN_IFACE = "org.freedesktop.login1.Manager"
SYSTEM_BUS = True


def load(mock, parameters):
    mock.AddMethods(MAIN_IFACE, [("CanRebootToFirmwareSetup", "", "s", f'ret = "{parameters.get("firmware", "yes")}"')])
