import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.common
import "history.js" as Saved

QtObject {
  id: root

  // A live Notification, or a PastNotification read back from the saved history.
  required property var notification
  required property string screen
  readonly property bool restored: notification?.past === true
  // Names its saved pictures, and it in the saved history.
  property string uid: ""
  // By role ("image"), the saved copy of a picture only the server held.
  property var kept: ({})
  property date time: new Date()
  property bool popup: false
  // Looked at in the center; the bar's bell shows while any is not.
  property bool checked: false
  // Below the screen's edge until there is room for it; this, or no monitor on to show it, holds the timeout.
  property bool waiting: false
  readonly property bool unseen: waiting || !Screens.has(screen)
  // Under the pointer, being read, as GNOME holds a banner.
  property bool hovered: false

  readonly property bool critical: notification.urgency === NotificationUrgency.Critical
  // As the notification names them: a theme icon, a picture only the server holds, or a file.
  readonly property var sources: ({ image: Notifs.picture(notification.image), appIcon: Notifs.appIcon(notification) })
  readonly property string appIcon: root.shown("appIcon")
  readonly property string image: root.shown("image")
  // By path, a client's files copied into the cache, "" where one could not be: only a copy is drawn, as the file could be a pipe or on a hung mount, which would hold the shell.
  property var copies: new Map()
  readonly property var files: [...new Set([sources.image, sources.appIcon].map(source => Saved.localPath(source)))].filter(path => path !== "" && !path.startsWith(`${History.images}/`))
  readonly property var pending: files.filter(path => !copies.has(path))
  readonly property bool copying: pending.length > 0
  readonly property string key: Notifs.key(notification)
  readonly property string summary: Notifs.clip(notification.summary, Notifs.maxSummary)
  readonly property string body: Notifs.cleanBody(Notifs.clip(notification.body, Notifs.maxBody))
  readonly property NotificationAction defaultAction: Array.from(notification.actions).find(a => a.identifier === "default") ?? null
  readonly property var buttons: Array.from(notification.actions).filter(a => a.identifier !== "default")
  readonly property var progress: notification.hints.value

  readonly property int timeout: {
    if (critical) return 0;
    const requested = notification.expireTimeout;
    return requested < 0 ? Notifs.defaultTimeout : requested;
  }

  function source(): string {
    return String(notification.image ?? "");
  }

  // A picture only the server holds, and only while the notification lives, not saved yet.
  function wants(): bool {
    return !root.restored && !root.kept.image && Notifs.inMemory(root.source());
  }

  // A grab of the picture, from the copy the pictures' window drew.
  function keep(result: var): void {
    if (!root.wants()) return;
    const path = `${History.images}/${root.uid}-image.png`;
    if (result.saveToFile(path)) root.kept = { image: Saved.fileUrl(path) };
  }

  // What is drawn for ROLE: a client's file only as its copy, nothing until there is one.
  function shown(role: string): string {
    const path = Saved.localPath(root.sources[role]);
    return root.files.includes(path) ? root.copies.get(path) ?? "" : root.sources[role];
  }

  // What the saved history keeps for ROLE, named RAW by the notification: a file as its copy, nothing only the server holds.
  function lasting(role: string, raw: string): string {
    if (Saved.localPath(root.sources[role]) !== "") return root.shown(role);
    return Notifs.inMemory(raw) ? "" : raw;
  }

  // Copies what is pending, and deletes the copies of files no longer named.
  function copy(): void {
    if (copier.running || root.pending.length === 0) return;
    copier.jobs = root.pending.map(from => ({ from, to: `${History.images}/${root.uid}-${Qt.md5(from)}.png` }));
    copier.stale = [...root.copies.keys()].filter(path => !root.files.includes(path));
    const old = copier.stale.map(path => Saved.localPath(root.copies.get(path))).filter(path => path !== "");
    // A plain file of a picture's size, read with a deadline, as a pipe swapped in after the test would never answer.
    copier.command = ["sh", "-c", 'dir=$1; shift; [ -d "$dir" ] || mkdir -p "$dir"; while [ "$1" != -- ]; do if [ -f "$1" ] && timeout 2 head -c 10000001 -- "$1" > "$2" && [ "$(wc -c < "$2")" -le 10000000 ]; then echo "$2"; else rm -f "$2"; fi; shift 2; done; shift; rm -f -- "$@"', "sh", History.images, ...copier.jobs.reduce((args, job) => [...args, job.from, job.to], []), "--", ...old];
    copier.running = true;
  }

  onPendingChanged: root.copy()
  onCopiesChanged: Notifs.remember()
  Component.onCompleted: root.copy()

  function restartTimeout(): void {
    if (countdown.running) countdown.restart();
  }

  // Closed in the same tick as an update, it is not put back; past the flood limit an update only changes its card.
  function reshow(): void {
    if (root.lock.retained || !Notifs.entries.includes(root)) return;
    if (Notifs.admit(root.notification, true)) Notifs.present(root, Notifs.wantsPopup(critical));
  }

  // A resident notification stays open once invoked, so its popup goes by hand, as GNOME's does.
  function invoke(action: NotificationAction): void {
    action.invoke();
    popup = false;
  }

  // Dismisses the notification shown now, after a slide, unless it has closed or been replaced since; false when replaced, as the entry stays (the one replaced may be gone, and calling it throws).
  function dismissal(): var {
    const shown = notification;
    return () => {
      if (shown !== root.notification) return false;
      if (shown && !root.lock.retained) shown.dismiss();
      return true;
    };
  }

  onNotificationChanged: kept = ({})
  onKeptChanged: Notifs.remember()

  onPopupChanged: {
    if (popup) return;
    // Transient notifications stay out of the history.
    if (notification.transient && !lock.retained) notification.expire();
    else Notifs.trimHistory();
  }

  // Keeps the closed notification readable while the views slide it away.
  property RetainableLock lock: RetainableLock {
    object: root.restored ? null : root.notification
    locked: true
  }

  // The share of the timeout left; paused while unseen or under the pointer, so it carries on after.
  property real remaining: 1
  property NumberAnimation countdown: NumberAnimation {
    target: root
    property: "remaining"
    from: 1
    to: 0
    duration: root.timeout
    running: root.popup && root.timeout > 0 && !root.lock.retained
    paused: running && (root.unseen || root.hovered)
    onFinished: root.popup = false
  }

  // An update by id can change any of these alone, a progress value say.
  property Connections updates: Connections {
    target: root.notification

    function onSummaryChanged() {
      Qt.callLater(root.reshow);
    }

    function onBodyChanged() {
      Qt.callLater(root.reshow);
    }

    function onHintsChanged() {
      Qt.callLater(root.reshow);
    }

    function onUrgencyChanged() {
      Qt.callLater(root.reshow);
    }

    function onActionsChanged() {
      Qt.callLater(root.reshow);
    }

    function onImageChanged() {
      root.kept = ({});
      Qt.callLater(root.reshow);
    }
  }

  property Process copyProcess: Process {
    id: copier

    property var jobs: []
    property var stale: []

    stdout: StdioCollector {
      id: copied
    }
    onRunningChanged: {
      if (running) return;
      const done = new Set(copied.text.split("\n"));
      const copies = new Map([...root.copies].filter(([path]) => !copier.stale.includes(path)));
      for (const job of copier.jobs) copies.set(job.from, done.has(job.to) ? Saved.fileUrl(job.to) : "");
      root.copies = copies;
      root.copy();
    }
  }
}
