import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.common

QtObject {
  id: root

  // A live Notification, or a PastNotification read back from the saved history.
  required property var notification
  required property string screen
  readonly property bool restored: notification?.past === true
  // Names its saved pictures, and it in the saved history.
  property string uid: ""
  // By role ("image", "appIcon"), the saved copies of pictures only the server held.
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
  readonly property string appIcon: Notifs.appIcon(notification)
  readonly property string image: Notifs.picture(notification.image)
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

  function source(role: string): string {
    return String((role === "image" ? notification.image : notification.appIcon) ?? "");
  }

  // A picture only the server holds, and only while the notification lives, not saved yet.
  function wants(role: string): bool {
    return !root.restored && !root.kept[role] && Notifs.inMemory(root.source(role));
  }

  // A grab of the picture for ROLE, from the copy the popups' window drew.
  function keep(role: string, result: var): void {
    if (!root.wants(role)) return;
    const path = `${History.images}/${root.uid}-${role}.png`;
    if (result.saveToFile(path)) root.kept = Object.assign({}, root.kept, { [role]: `file://${path}` });
  }

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
}
