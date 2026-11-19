pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.common
import "markup.js" as Markup

Singleton {
  id: root

  property var entries: []
  readonly property var popups: entries.filter(e => e.popup)
  readonly property int unchecked: entries.filter(e => !e.checked).length

  // Saved, so a rebuild restarting the shell keeps it.
  property alias dnd: state.dnd

  readonly property int defaultTimeout: 8000
  readonly property int maxPopups: 5
  // As GNOME keeps per app.
  readonly property int perApp: 3

  // Like GNOME: over a fullscreen window only critical notifications pop up, and going fullscreen puts the others away.
  readonly property bool fullscreen: ToplevelManager.activeToplevel?.fullscreen ?? false
  onFullscreenChanged: {
    if (fullscreen) {
      for (const entry of entries) {
        if (!entry.critical) entry.popup = false;
      }
    }
  }

  function appKey(entry) {
    return entry.notification.desktopEntry || entry.notification.appName;
  }

  // Volume and brightness scripts send one of these so a new value replaces the last.
  function tag(notification) {
    return notification.hints["x-canonical-private-synchronous"] || notification.hints["x-dunst-stack-tag"] || "";
  }

  function wantsPopup(critical) {
    return Panels.active !== "center" && (critical || (!dnd && !fullscreen));
  }

  // First in the list, on the focused monitor once it pops up again, with its sound, within the limit.
  function present(entry, popup) {
    const wasShown = entry.popup;
    root.entries = [entry, ...root.entries.filter(e => e !== entry)];
    entry.time = new Date();
    if (popup && !wasShown) entry.screen = Screens.focused;
    entry.checked = Panels.active === "center";
    entry.popup = popup;
    entry.restartTimeout();
    root.trimPopups(entry);
    root.trimHistory();
    if (entry.popup && !wasShown) root.playSound(entry.notification);
  }

  // The newest one stays; of the rest the oldest go first, and those meant to stay (critical, or no timeout) last.
  function trimPopups(newest) {
    const extra = root.popups.length - root.maxPopups;
    if (extra <= 0) return;
    const oldest = root.popups.filter(e => e !== newest).reverse();
    const order = [...oldest.filter(e => e.timeout > 0), ...oldest.filter(e => e.timeout === 0)];
    for (const entry of order.slice(0, extra)) entry.popup = false;
  }

  // One still popped up is kept until its popup goes.
  function trimHistory() {
    const counts = {};
    for (const entry of root.entries.slice()) {
      const key = root.appKey(entry);
      counts[key] = (counts[key] ?? 0) + 1;
      if (counts[key] > root.perApp && !entry.popup) entry.notification.expire();
    }
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
    return Markup.markup(body).trim().replace(/\n{3,}/g, "\n\n");
  }

  function appIcon(notification) {
    return iconSource(notification.appIcon) || (notification.appName ? iconSource(DesktopEntries.heuristicLookup(notification.appName)?.icon) : "");
  }

  // A theme icon the theme lacks would draw nothing where the app's icon or initial should be.
  function picture(source) {
    const icon = /^image:\/\/icon\/(.+)$/.exec(source);
    return icon && !Quickshell.hasThemeIcon(icon[1]) ? "" : source;
  }

  // A picture only the server holds goes when the notification does; a theme icon or a file outlives it.
  function inMemory(source) {
    return source.startsWith("image://") && !source.startsWith("image://icon/");
  }

  function iconSource(icon) {
    if (!icon) return "";
    if (icon.startsWith("file://") || icon.startsWith("image://")) return icon;
    if (icon.startsWith("/")) return `file://${icon}`;
    return Quickshell.iconPath(icon, true);
  }

  function openUrl(url) {
    if (!Markup.safeLink(url)) return;
    Detached.run(["xdg-open", url], "");
  }

  // Low urgency is silent, whatever the app asks; a sound-name is looked up in the freedesktop theme, ours if it is not there.
  function playSound(notification) {
    const hints = notification.hints;
    if (hints["suppress-sound"] || notification.urgency === NotificationUrgency.Low) return;
    const ours = Quickshell.shellPath(`notifications/sounds/${notification.urgency === NotificationUrgency.Critical ? "critical.ogg" : "notification.oga"}`);
    const file = hints["sound-file"]?.replace(/^file:\/\//, "");
    const name = hints["sound-name"] ?? "";
    if (file) {
      Quickshell.execDetached(["pw-play", file]);
    } else if (/^[a-z0-9-]+$/.test(name)) {
      Quickshell.execDetached(["sh", "-c", 'IFS=:; for dir in ${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/share}; do for ext in oga ogg wav; do [ -f "$dir/sounds/freedesktop/stereo/$1.$ext" ] && exec pw-play "$dir/sounds/freedesktop/stereo/$1.$ext"; done; done; exec pw-play "$2"', "sh", name, ours]);
    } else {
      Quickshell.execDetached(["pw-play", ours]);
    }
  }

  // A tag's replacement takes the entry over, and the notification it replaced closes without it.
  function watch(entry) {
    const notification = entry.notification;
    notification.closed.connect(() => {
      if (notification.past) notification.destroy(1000);
      if (entry.notification !== notification) return;
      root.entries = root.entries.filter(e => e !== entry);
      // Once the views have slid it away.
      entry.destroy(1000);
    });
  }

  // The history as saved: no transient ones, and pictures only the server held by their saved copies.
  function record(entry) {
    const notification = entry.notification;
    const lasting = (role, source) => entry.kept[role] ?? (root.inMemory(source ?? "") ? "" : source ?? "");
    return {
      uid: entry.uid,
      time: entry.time.getTime(),
      checked: entry.checked,
      appName: notification.appName ?? "",
      appIcon: lasting("appIcon", notification.appIcon),
      desktopEntry: notification.desktopEntry ?? "",
      summary: notification.summary ?? "",
      body: notification.body ?? "",
      image: lasting("image", notification.image),
      urgency: notification.urgency
    };
  }

  function remember() {
    saving.restart();
  }

  onEntriesChanged: remember()
  onUncheckedChanged: remember()

  Timer {
    id: saving

    interval: 500
    onTriggered: History.save(root.entries.filter(entry => !entry.notification.transient).map(entry => root.record(entry)))
  }

  function key(notification) {
    return `${notification.appName}\n${notification.summary}\n${notification.body}`;
  }

  // A reload hands the live notifications over too; one already read back from disk becomes the live one.
  Connections {
    target: History

    function onRestored(records) {
      const live = new Set(root.entries.map(entry => root.key(entry.notification)));
      const restored = records.filter(record => !live.has(root.key(record))).map(record => {
        const notification = pastComponent.createObject(root, {
          appName: record.appName,
          appIcon: record.appIcon,
          desktopEntry: record.desktopEntry,
          summary: record.summary,
          body: record.body,
          image: record.image,
          urgency: record.urgency
        });
        const entry = entryComponent.createObject(root, {
          notification,
          screen: "",
          uid: record.uid,
          time: new Date(record.time),
          checked: record.checked
        });
        root.watch(entry);
        return entry;
      });
      root.entries = [...root.entries, ...restored].sort((a, b) => b.time - a.time);
      root.trimHistory();
    }
  }

  Connections {
    target: Panels

    function onActiveChanged(): void {
      if (Panels.active !== "center") return;
      for (const entry of root.entries) entry.checked = true;
    }
  }

  // One whose monitor has gone moves to the focused one for good, rather than back when it returns.
  Connections {
    target: Screens

    function onRealChanged() {
      for (const entry of root.entries) {
        if (!Screens.has(entry.screen)) entry.screen = Screens.focused;
      }
    }
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

  Component {
    id: pastComponent

    PastNotification {}
  }

  NotificationServer {
    actionsSupported: true
    bodyHyperlinksSupported: true
    bodyMarkupSupported: true
    imageSupported: true
    persistenceSupported: true
    extraHints: ["sound"]

    onNotification: notification => {
      const tag = root.tag(notification);
      const same = (tag ? root.entries.find(entry => root.tag(entry.notification) === tag) : null)
        ?? (notification.lastGeneration ? root.entries.find(entry => entry.restored && root.key(entry.notification) === root.key(notification)) : null)
        ?? null;
      // A reload hands every notification over again; they have been seen.
      const popup = !notification.lastGeneration && root.wantsPopup(notification.urgency === NotificationUrgency.Critical);
      if (notification.transient && !popup) {
        same?.notification.expire();
        // Untracked, the server drops it; expired here, the app hears it expired rather than that it was dismissed.
        notification.expire();
        return;
      }
      notification.tracked = true;

      // In place, as an update by id is, so it does not slide out and in again.
      let entry = same;
      if (same) {
        const old = same.notification;
        same.notification = notification;
        old.expire();
      } else {
        entry = entryComponent.createObject(root, {
          notification,
          screen: Screens.focused
        });
      }
      root.watch(entry);
      root.present(entry, popup);
    }
  }
}
