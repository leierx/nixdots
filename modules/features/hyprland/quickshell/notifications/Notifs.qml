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
  // An app saying the same again within it updates the card it has, as a stack tag does.
  readonly property int repeatWindow: 2000
  // A burst of popups is one sound: no more than one per this, critical ones counted apart.
  readonly property int soundGap: 300
  property real soundAt: 0
  property real criticalSoundAt: 0
  // Each entry's uid takes the next, so a burst created in one millisecond names its pictures apart.
  property int issued: 0
  // As many as the saved history keeps; past it the oldest go, so a flood from many apps costs no more than one from a few.
  readonly property int maxEntries: 100
  // Past this many a second, critical ones counted apart, the rest are turned away at the door, where they cost next to nothing.
  readonly property int floodLimit: 30
  // Text past these is never read, and laying out a megabyte of it held the shell for seconds.
  readonly property int maxSummary: 500
  readonly property int maxBody: 5000
  readonly property int maxApp: 100
  // Plain, since it changes with every notification: the second counted, what it let in, and what it turned away by app.
  property var flood: ({ second: 0, normal: 0, critical: 0, total: 0, dropped: {} })

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
    return root.clip(entry.notification.desktopEntry || entry.notification.appName, root.maxApp);
  }

  function nextUid() {
    return (Date.now() * 1000 + root.issued++ % 1000).toString(36);
  }

  function clip(text, length) {
    return text && text.length > length ? `${text.slice(0, length)}…` : text ?? "";
  }

  function admit(notification) {
    const flood = root.flood;
    const second = Math.floor(Date.now() / 1000);
    if (second !== flood.second) {
      flood.second = second;
      flood.normal = 0;
      flood.critical = 0;
    }
    const kind = notification.urgency === NotificationUrgency.Critical ? "critical" : "normal";
    if (flood[kind] < root.floodLimit) {
      flood[kind]++;
      return true;
    }
    const app = root.clip(notification.appName, root.maxApp) || "An app";
    const apps = Object.keys(flood.dropped);
    const key = app in flood.dropped || apps.length < 20 ? app : "others";
    flood.dropped[key] = (flood.dropped[key] ?? 0) + 1;
    flood.total++;
    floodOver.restart();
    return false;
  }

  // Once a flood has stopped, one card says what it turned away.
  Timer {
    id: floodOver

    interval: 2000
    onTriggered: {
      const counts = Object.entries(root.flood.dropped).sort((a, b) => b[1] - a[1]);
      const named = counts.filter(([app]) => app !== "others").slice(0, 3).map(([app]) => app);
      const from = counts.length > named.length ? `${named.join(", ")} and others` : named.length > 1 ? `${named.slice(0, -1).join(", ")} and ${named[named.length - 1]}` : named[0];
      const total = root.flood.total;
      root.flood.total = 0;
      root.flood.dropped = {};
      Quickshell.execDetached(["notify-send", "-a", "Notifications", "-i", "dialog-warning", `${total.toLocaleString(Qt.locale(), "f", 0)} Notifications Dropped`, `${from} sent more than ${root.floodLimit} a second.`]);
    }
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
    let kept = 0;
    for (const entry of root.entries.slice()) {
      const key = root.appKey(entry);
      counts[key] = (counts[key] ?? 0) + 1;
      if (!entry.popup && (counts[key] > root.perApp || kept >= root.maxEntries)) entry.notification.expire();
      else kept++;
    }
  }

  // As CloseNotification would, for a card the shell itself sent.
  function close(id) {
    root.entries.find(entry => entry.notification.id === id)?.notification.expire();
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
    return iconSource(notification.appIcon) || (notification.appName ? iconSource(DesktopEntries.heuristicLookup(root.clip(notification.appName, root.maxApp))?.icon) : "");
  }

  // A theme icon the theme lacks would draw nothing where the app's icon or initial should be; a bare path (notify-send -i /file) comes as one.
  function picture(source) {
    const icon = /^image:\/\/icon\/(.+)$/.exec(source);
    if (icon && icon[1].startsWith("/")) return `file://${icon[1]}`;
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
    // A flood under way, one turned away in the last two seconds, is silent.
    if (hints["suppress-sound"] || notification.urgency === NotificationUrgency.Low || floodOver.running) return;
    const now = Date.now();
    const critical = notification.urgency === NotificationUrgency.Critical;
    if (now - (critical ? root.criticalSoundAt : root.soundAt) < root.soundGap) return;
    if (critical) root.criticalSoundAt = now;
    else root.soundAt = now;
    const ours = Quickshell.shellPath(`notifications/sounds/${critical ? "critical.ogg" : "notification.oga"}`);
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
      appName: root.clip(notification.appName, root.maxApp),
      appIcon: lasting("appIcon", notification.appIcon),
      desktopEntry: root.clip(notification.desktopEntry, root.maxApp),
      summary: root.clip(notification.summary, root.maxSummary),
      body: root.clip(notification.body, root.maxBody),
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
    return `${root.clip(notification.appName, root.maxApp)}\n${root.clip(notification.summary, root.maxSummary)}\n${root.clip(notification.body, root.maxBody)}`;
  }

  // A reload hands the live notifications over too; one already read back from disk becomes the live one.
  Connections {
    target: History

    function onRestored(records) {
      const live = new Set(root.entries.map(entry => entry.key));
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
      const key = root.key(notification);
      const now = Date.now();
      const same = (tag ? root.entries.find(entry => root.tag(entry.notification) === tag) : null)
        ?? (notification.lastGeneration ? root.entries.find(entry => entry.restored && entry.key === key) : null)
        ?? root.entries.find(entry => !entry.restored && now - entry.time.getTime() < root.repeatWindow && entry.key === key)
        ?? null;
      // An update in place grows nothing, so only what would add a card counts.
      if (!same && !notification.lastGeneration && !root.admit(notification)) {
        notification.expire();
        return;
      }
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
          screen: Screens.focused,
          uid: root.nextUid()
        });
      }
      root.watch(entry);
      root.present(entry, popup);
    }
  }
}
