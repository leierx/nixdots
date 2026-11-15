pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.common

// The notification daemon. Every notification stays in `entries`, the
// notification center's history, until it is dismissed; `popups` are the ones
// currently shown in the corner of a monitor.
Singleton {
  id: root

  // Newest first.
  property var entries: []
  readonly property var popups: entries.filter(e => e.popup)

  // Do not disturb: popups only for critical notifications. Saved, so a
  // rebuild restarting the shell keeps it.
  property alias dnd: state.dnd

  readonly property int defaultTimeout: 8000
  readonly property int maxPopups: 5

  // Ticks the "5m" ages on the cards.
  property date now: new Date()

  function wantsPopup(critical) {
    return Panels.active !== "center" && (!dnd || critical);
  }

  function hidePopups() {
    for (const entry of entries) entry.popup = false;
  }

  function clear() {
    // Dismissing removes the entry, so walk a copy.
    for (const entry of entries.slice()) entry.notification.dismiss();
  }

  // "now", "5m", "3h", then the date; ticks with `now`.
  function age(time) {
    const seconds = (now - time) / 1000;
    if (seconds < 60) return "now";
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h`;
    return Qt.formatDate(time, "d MMM");
  }

  // The app's icon: the one it sends, else its desktop entry's.
  function appIcon(notification) {
    return iconSource(notification?.appIcon) || (notification?.appName ? iconSource(DesktopEntries.heuristicLookup(notification.appName)?.icon) : "");
  }

  function iconSource(icon) {
    if (!icon) return "";
    if (icon.startsWith("file://")) return icon;
    if (icon.startsWith("/")) return `file://${icon}`;
    return Quickshell.iconPath(icon, true);
  }

  function openUrl(url) {
    Quickshell.execDetached(["systemd-run", "--user", "--scope", "--quiet", "xdg-open", url]);
  }

  // The app's own sound if it sends one; low urgency is silent.
  function playSound(notification) {
    const hints = notification.hints;
    if (hints["suppress-sound"]) return;
    const own = hints["sound-file"]?.replace(/^file:\/\//, "");
    const ours = ["", "notification.oga", "critical.ogg"][notification.urgency];
    const file = own || (ours && Quickshell.shellPath(`notifications/sounds/${ours}`));
    if (file) Quickshell.execDetached(["pw-play", file]);
  }

  // The monitor a new popup goes to.
  function focusedScreen() {
    return Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }

  FileView {
    path: Quickshell.statePath("notifications.json")
    // Until do not disturb is first switched, there is no file, which is fine.
    printErrors: false
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      if (error !== FileViewError.FileNotFound) console.warn(`Reading ${path} failed: ${FileViewError.toString(error)}`);
    }
    onSaveFailed: error => console.warn(`Writing ${path} failed: ${FileViewError.toString(error)}`)

    JsonAdapter {
      id: state

      property bool dnd: false
    }
  }

  Component {
    id: entryComponent

    NotifEntry {}
  }

  NotificationServer {
    actionsSupported: true
    bodyHyperlinksSupported: true
    bodyMarkupSupported: true
    imageSupported: true
    persistenceSupported: true

    onNotification: notification => {
      notification.tracked = true;

      // A newer notification with the same tag replaces the old one, as
      // volume and brightness scripts expect.
      const tag = notification.hints["x-canonical-private-synchronous"];
      if (tag) {
        for (const entry of root.entries.slice()) {
          if (entry.notification.hints["x-canonical-private-synchronous"] === tag) entry.notification.expire();
        }
      }

      const entry = entryComponent.createObject(root, {
        notification,
        screen: root.focusedScreen()
      });
      notification.closed.connect(() => {
        root.entries = root.entries.filter(e => e !== entry);
        // Once the views have slid it away.
        entry.destroy(1000);
      });
      root.entries = [entry, ...root.entries];
      entry.popup = root.wantsPopup(entry.critical);
      if (entry.popup) root.playSound(notification);
      else if (notification.transient) notification.expire();

      for (const old of root.popups.slice(root.maxPopups)) old.popup = false;
    }
  }
}
