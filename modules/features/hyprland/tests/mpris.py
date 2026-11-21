"""An MPRIS player for qs-test, loaded into a mock that owns org.mpris.MediaPlayer2.NAME.

Its buttons work: play, pause, next and previous move through a short list of tracks.
A new track's length comes once and then goes from its metadata until a pause sends it again, as Firefox does on YouTube.
qs-test starts one per player (`qst player add NAME`, the name in QS_MPRIS_NAME) and drives it through the mock.
"""

import os

import dbus

from dbusmock import MOCK_IFACE

# Read as the mock starts, so the player is whole before anyone sees its name.
BUS_NAME = "org.mpris.MediaPlayer2." + os.environ.get("QS_MPRIS_NAME", "qstest")
MAIN_OBJ = "/org/mpris/MediaPlayer2"
MAIN_IFACE = "org.mpris.MediaPlayer2"
SYSTEM_BUS = False

ROOT_IFACE = "org.mpris.MediaPlayer2"
PLAYER_IFACE = "org.mpris.MediaPlayer2.Player"
PATH = "/org/mpris/MediaPlayer2"

player = {"tracks": [], "index": 0, "art": ""}


def metadata(index, length=True):
    title, artist, seconds = player["tracks"][index]
    return dbus.Dictionary({
        "mpris:trackid": dbus.ObjectPath(f"/org/qstest/track/{index}"),
        **({"mpris:length": dbus.Int64(seconds * 1000000)} if length else {}),
        "xesam:title": dbus.String(title),
        "xesam:artist": dbus.Array([dbus.String(artist)], signature="s"),
        **({"mpris:artUrl": dbus.String(player["art"])} if player["art"] else {}),
    }, signature="sv")


def changed(mock, props):
    mock.props[PLAYER_IFACE].update(props)
    mock.EmitSignal(dbus.PROPERTIES_IFACE, "PropertiesChanged", "sa{sv}as", [PLAYER_IFACE, dbus.Dictionary(props, signature="sv"), dbus.Array([], signature="s")])


def go(mock, step):
    player["index"] = (player["index"] + step) % len(player["tracks"])
    changed(mock, {"Metadata": metadata(player["index"]), "Position": dbus.Int64(0)})
    changed(mock, {"Metadata": metadata(player["index"], length=False)})


def status(mock, value):
    changed(mock, {"PlaybackStatus": dbus.String(value)})
    if value == "Paused":
        changed(mock, {"Metadata": metadata(player["index"])})


def load(mock, parameters):
    player["art"] = parameters.get("art", "")
    player["tracks"] = [tuple(track) for track in parameters.get("tracks", [["Everything In Its Right Place", "Radiohead", 251], ["Kid A", "Radiohead", 284], ["The National Anthem", "Radiohead", 351]])]
    mock.AddProperties(ROOT_IFACE, {
        "Identity": dbus.String(parameters.get("identity", "Player")),
        "DesktopEntry": dbus.String(parameters.get("desktop", "")),
        "CanRaise": True,
        "CanQuit": True,
        "HasTrackList": False,
        "SupportedUriSchemes": dbus.Array([], signature="s"),
        "SupportedMimeTypes": dbus.Array([], signature="s"),
    })
    mock.AddMethods(ROOT_IFACE, [("Raise", "", "", "self.log('raised')"), ("Quit", "", "", "")])
    mock.AddProperties(PLAYER_IFACE, {
        "PlaybackStatus": dbus.String(parameters.get("status", "Playing")),
        "LoopStatus": dbus.String("None"),
        "Rate": dbus.Double(1.0),
        "Shuffle": False,
        "Metadata": metadata(0),
        "Volume": dbus.Double(1.0),
        "Position": dbus.Int64(96 * 1000000),
        "MinimumRate": dbus.Double(1.0),
        "MaximumRate": dbus.Double(1.0),
        "CanGoNext": bool(parameters.get("next", True)),
        "CanGoPrevious": bool(parameters.get("previous", True)),
        "CanPlay": True,
        "CanPause": True,
        "CanSeek": True,
        "CanControl": True,
    })
    mock.AddMethods(PLAYER_IFACE, [
        ("Play", "", "", "self.mpris_status(self, 'Playing')"),
        ("Pause", "", "", "self.mpris_status(self, 'Paused')"),
        ("Stop", "", "", "self.mpris_status(self, 'Stopped')"),
        ("PlayPause", "", "", "self.mpris_status(self, 'Paused' if self.props['org.mpris.MediaPlayer2.Player']['PlaybackStatus'] == 'Playing' else 'Playing')"),
        ("Next", "", "", "self.mpris_go(self, 1)"),
        ("Previous", "", "", "self.mpris_go(self, -1)"),
        ("Seek", "x", "", ""),
        ("SetPosition", "ox", "", "self.props['org.mpris.MediaPlayer2.Player']['Position'] = dbus.Int64(args[1]); self.EmitSignal('org.mpris.MediaPlayer2.Player', 'Seeked', 'x', [args[1]])"),
        ("OpenUri", "s", "", ""),
    ])
    mock.mpris_status = status
    mock.mpris_go = go


@dbus.service.method(MOCK_IFACE, in_signature="s", out_signature="")
def SetStatus(self, value):
    status(self, str(value))
