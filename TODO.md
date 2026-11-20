# TODO

## Upstream candidates

- **`DelegateModel::cancel: index out range`** (Qt, qtdeclarative). Logged when
  launcher modes are toggled concurrently by script; never seen by hand.
  Repro in a qs-test session:
  `for i in $(seq 40); do for p in apps clipboard monitors windows nixpkgs; do qst ipc panels toggle $p & done; wait; done; qst problems`
  (about 18 warnings). Pairs of sequential switches never warn. Likely
  `LauncherWindow`'s `ResultList` (a `ListView` with `asynchronous` delegates)
  having its model swapped while a delegate still incubates, so the cancel
  lands on an index the new model no longer has. Not yet confirmed whether
  this is Qt's bug or our use: first reduce it to a bare `ListView` with an
  async delegate and a model replaced mid-incubation, then check Qt's bug
  tracker (QQmlDelegateModel::cancel) before filing. Cosmetic as far as
  seen: the launcher still opens and lists right.

- **Quickshell.Networking picks its backend once** (Quickshell 0.3.2,
  `src/network/qml.cpp`): `Networking` tries NetworkManager as it is first
  used and, if NetworkManager is not on the bus then, logs "Network will not
  work" and never tries again, so a NetworkManager started after the shell
  needs the shell restarted. Restarting NetworkManager later is handled (a
  service watcher). The control centre shows "Network · Not available" for as
  long. Repro: `QS_TEST_NETWORK=none qst reset`, then `qst network start`.
  Worth an issue: retry on the service registering, as the backend already
  watches for it.
- **Quickshell asks for every access point at once** (0.3.2,
  `NMWirelessDevice::registerAccessPoint`): one `GetAll` per access point,
  all in flight together, and the system bus allows 128 pending replies per
  connection (`max_replies_per_connection`), so past about 128 access points
  the rest fail with `LimitsExceeded` and are never asked again: those
  networks are missing from the list until the shell restarts. qs-test's bus
  raises the limit so its 300-network case tests the list itself. Worth an
  issue: queue the calls, or retry the failed ones.
- **Quickshell's Bluetooth type info names `BluetoothAdapter` unqualified**
  (`Bluetooth.defaultAdapter`, `BluetoothDevice.adapter`), so qmllint cannot
  resolve it; `qs-lint` mends it, as it does `FileView.adapter`.
- **python-dbusmock 0.37.2**: `UpdateProperties` cannot wrap a
  `dbus.ObjectPath` ("no attribute 'conjugate'"), and the bluez5 template's
  `StartDiscovery` raises a `KeyError` until a discovery filter is set. The
  test templates work round both; small enough to send upstream as fixes.

## To chase

- **Slow memory growth under notification floods.** Handover below.

### Handover: memory growth under floods

What was seen (2026-11-20, qs-test session, Quickshell 0.3.2 from
`pkgs.unstable`): RSS after idling 45 s between rounds of
`qst flood 1000000 --urgency 2` went 416 → 438 → 446 → 453 MiB, so +22,
+8, +7 MiB a round, slowing. The 10,000,000 run went 422 → 504 MiB over
17 minutes. The flood guard admits about 30 a second, so roughly 3,100
notifications are actually made per million sent: about 2 KB each that
does not come back. Everything turned away at the door costs nothing
measurable. In normal use that is a few MB a day, and every rebuild that
changes the shell restarts it.

First question: garbage the V4 heap has not collected (or collected
without returning memory to the OS), or a real leak?

1. Add to `tests/Probe.qml`'s `IpcHandler` a `function gc(): void { gc(); }`
   (the JS global), and compare RSS before and after forcing it at idle.
2. Run qs with `MALLOC_ARENA_MAX=2`, and try `malloc_trim(0)` (gdb
   `call malloc_trim(0)` on the qs pid): if RSS drops back, it is
   fragmentation, not a leak.
3. If it still grows: `heaptrack qs -p <shell>` over a 500k flood, or the QML
   profiler (`QML_PROFILER`/`qmlprofiler`) for object counts.

Suspects, by where entries are made and dropped (`notifications/`):

- `Notifs.watch()` connects a JS closure to each notification's `closed`;
  the connection may keep the closure, and through it the entry, alive.
- `NotifEntry` is destroyed `entry.destroy(1000)` after close; check that
  every path gets there (expired by `trimHistory`, trimmed popups,
  replaced by a tag or a repeat, where `old.expire()` runs on a
  notification no entry holds any more).
- `PastNotification`s are destroyed only through `notification.past`.
- Each popup builds a `NotificationCard` delegate (shadow, countdown
  animation) and slides it out over a second; check those go.
- The off-screen picture `Repeater` in `NotificationPopups.qml` rebuilds
  its model on every change of `entries`.

Repro: `qst up`, then `qst flood 1000000 --urgency 2` a few times, reading
`VmRSS` from `/proc/$(qst status | awk '{print $NF}')/status` after each.
A fix gets a chaos.sh case that floods and asserts RSS settles within a
few MiB of where it started (the per-case `QS_TEST_PEAK` budget is too
coarse for this).

### Control centre: left open on purpose

- Only the first Wi-Fi card is shown; a second (a USB stick beside the
  built-in one) is left to Network Settings.
- Hidden networks and 802.1X (eduroam) go through nm-connection-editor; the
  centre asks only for a WPA password.
- Bluetooth pairing that needs a PIN or a confirmed code goes to bluetui:
  Quickshell has no pairing agent. Writing one (`org.bluez.Agent1` from QML)
  would need D-Bus object export, which Quickshell lacks.
- Night light has no schedule (sunset to sunrise from the weather's
  coordinates was offered and not wanted yet).

