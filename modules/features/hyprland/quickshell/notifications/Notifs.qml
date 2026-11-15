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
    return Panels.active !== "notifications" && (!dnd || critical);
  }

  function hidePopups() {
    for (const entry of entries) entry.popup = false;
  }

  function clear() {
    // Dismissing removes the entry, so walk a copy.
    for (const entry of entries.slice()) entry.notification.dismiss();
  }

  function openUrl(url) {
    Quickshell.execDetached(["systemd-run", "--user", "--scope", "--quiet", "xdg-open", url]);
  }

  // The app's own sound if it sends one; low urgency is silent.
  function playSound(notification) {
    const hints = notification.hints;
    if (hints["suppress-sound"]) return;
    const file = hints["sound-file"]?.replace(/^file:\/\//, "")
      || ["", "sounds/notification.oga", "sounds/critical.ogg"][notification.urgency];
    if (!file) return;
    const path = file.startsWith("/") ? file : Qt.resolvedUrl(file).toString().replace(/^file:\/\//, "");
    Quickshell.execDetached(["pw-play", path]);
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
          if (entry.notification.hints["x-canonical-private-synchronous"] === tag) entry.notification.dismiss();
        }
      }

      const entry = entryComponent.createObject(root, {
        notification,
        screen: root.focusedScreen()
      });
      notification.closed.connect(() => {
        root.entries = root.entries.filter(e => e !== entry);
        entry.destroy();
      });
      root.entries = [entry, ...root.entries];
      entry.popup = root.wantsPopup(entry.critical);
      if (entry.popup) root.playSound(notification);
      if (!entry.popup && notification.transient) notification.expire();

      for (const old of root.popups.slice(root.maxPopups)) old.popup = false;
    }
  }
}
