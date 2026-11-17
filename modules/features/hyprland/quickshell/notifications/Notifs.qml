pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.common

Singleton {
  id: root

  // Newest first.
  property var entries: []
  readonly property var popups: entries.filter(e => e.popup)

  // Only critical notifications pop up; saved, so a rebuild restarting the shell keeps it.
  property alias dnd: state.dnd

  readonly property int defaultTimeout: 8000
  readonly property int maxPopups: 5

  // Like GNOME: over a fullscreen window only critical notifications pop up, and going fullscreen puts the others away.
  readonly property bool fullscreen: ToplevelManager.activeToplevel?.fullscreen ?? false
  onFullscreenChanged: {
    if (fullscreen) {
      for (const entry of entries) {
        if (!entry.critical) entry.popup = false;
      }
    }
  }

  function wantsPopup(critical) {
    return Panels.active !== "center" && (critical || (!dnd && !fullscreen));
  }

  function hidePopups() {
    for (const entry of entries) entry.popup = false;
  }

  function clear() {
    // Dismissing removes the entry, so walk a copy.
    for (const entry of entries.slice()) entry.notification.dismiss();
  }

  function age(time) {
    const now = Time.now;
    const minutes = Math.floor((now - time) / 60000);
    if (minutes < 1) return "now";
    if (minutes < 60) return `${minutes}m`;
    const day = date => new Date(date.getFullYear(), date.getMonth(), date.getDate());
    // Rounded, since a day with a clock change is not 24 hours long.
    const days = Math.round((day(now) - day(time)) / 86400000);
    if (days === 0) return time.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
    if (days === 1) return "Yesterday";
    if (days < 7) return Qt.locale().toString(time, "dddd");
    return Qt.locale().toString(time, time.getFullYear() === now.getFullYear() ? "d MMM" : "d MMM yyyy");
  }

  // Chromium puts a link to the site first.
  function cleanBody(body) {
    const origin = /^<a href="([^"]*)">([^<]*)<\/a>(?:\n|$)/.exec(body);
    if (origin && origin[1].includes(origin[2])) body = body.slice(origin[0].length);
    return body.trim().replace(/\n{3,}/g, "\n\n");
  }

  function appIcon(notification) {
    return iconSource(notification.appIcon) || (notification.appName ? iconSource(DesktopEntries.heuristicLookup(notification.appName)?.icon) : "");
  }

  function iconSource(icon) {
    if (!icon) return "";
    if (icon.startsWith("file://")) return icon;
    if (icon.startsWith("/")) return `file://${icon}`;
    return Quickshell.iconPath(icon, true);
  }

  function openUrl(url) {
    Quickshell.execDetached({
      command: ["systemd-run", "--user", "--scope", "--quiet", "xdg-open", url],
      // The shell's own scale, from shell.qml, is not the browser's.
      environment: ({ QT_SCALE_FACTOR: null }),
    });
  }

  // Low urgency is silent.
  function playSound(notification) {
    const hints = notification.hints;
    if (hints["suppress-sound"]) return;
    const own = hints["sound-file"]?.replace(/^file:\/\//, "");
    const ours = ["", "notification.oga", "critical.ogg"][notification.urgency];
    const file = own || (ours && Quickshell.shellPath(`notifications/sounds/${ours}`));
    if (file) Quickshell.execDetached(["pw-play", file]);
  }

  function focusedScreen() {
    return Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
  }

  StateFile {
    name: "notifications.json"

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
      // Same tag replaces, as volume and brightness scripts expect.
      const tag = notification.hints["x-canonical-private-synchronous"];
      if (tag) {
        for (const entry of root.entries.slice()) {
          if (entry.notification.hints["x-canonical-private-synchronous"] === tag) entry.notification.expire();
        }
      }

      const popup = root.wantsPopup(notification.urgency === NotificationUrgency.Critical);
      // Left untracked, so the server drops it: expired in this handler, it is freed without a closed signal.
      if (notification.transient && !popup) return;
      notification.tracked = true;

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
      entry.popup = popup;
      if (popup) root.playSound(notification);

      for (const old of root.popups.slice(root.maxPopups)) old.popup = false;
    }
  }
}
