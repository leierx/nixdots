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
  property string uid: (Date.now() * 1000 + Math.floor(Math.random() * 1000)).toString(36)
  // By role ("image", "appIcon"), the saved copies of pictures only the server held.
  property var kept: ({})
  property date time: new Date()
  property bool popup: false
  // Looked at in the center; the bar's bell shows while any is not.
  property bool checked: false
  // The popup under the pointer holds the timeout.
  property bool hovered: false
  // So does one below the screen's edge, until there is room for it, or one with no monitor on to show it.
  property bool waiting: false
  readonly property bool unseen: waiting || !Screens.has(screen)
  // Above a hovered popup on its screen, so its going would move that one from under the pointer.
  readonly property bool above: {
    const stack = Notifs.popups.filter(e => e.screen === screen);
    const held = stack.findIndex(e => e.hovered);
    return held > 0 && stack.indexOf(root) < held;
  }

  readonly property bool critical: notification.urgency === NotificationUrgency.Critical
  readonly property string appIcon: Notifs.appIcon(notification)
  readonly property string image: Notifs.picture(notification.image)
  readonly property string body: Notifs.cleanBody(notification.body)
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

  // From the item drawing it, which NotificationPopups keeps out of sight for each one wanted.
  function keep(role: string, item: Item): void {
    if (!root.wants(role)) return;
    const path = `${History.images}/${root.uid}-${role}.png`;
    item.grabToImage(result => {
      if (result.saveToFile(path)) root.kept = Object.assign({}, root.kept, { [role]: `file://${path}` });
    }, Qt.size(item.sourceSize.width, item.sourceSize.height));
  }

  function restartTimeout(): void {
    if (countdown.running) countdown.restart();
  }

  function reshow(): void {
    Notifs.present(root, Notifs.wantsPopup(critical));
  }

  // A resident notification stays open once invoked, so its popup goes by hand, as GNOME's does.
  function invoke(action: NotificationAction): void {
    action.invoke();
    popup = false;
  }

  // Dismisses the notification shown now, after a slide, unless it has closed or been replaced since.
  function dismissal(): var {
    const shown = notification;
    return () => {
      if (shown && !(shown === root.notification && root.lock.retained)) shown.dismiss();
    };
  }

  onNotificationChanged: kept = ({})
  onKeptChanged: Notifs.remember()

  onPopupChanged: {
    if (popup) return;
    // A popup removed under the pointer never reports it gone.
    hovered = false;
    // Transient notifications stay out of the history.
    if (notification.transient) notification.expire();
    else Notifs.trimHistory();
  }

  // Keeps the closed notification readable while the views slide it away.
  property RetainableLock lock: RetainableLock {
    object: root.restored ? null : root.notification
    locked: true
  }

  // The share of the timeout left, which the popup's bar shows; holding it pauses it, so it carries on after.
  property real remaining: 1
  property NumberAnimation countdown: NumberAnimation {
    target: root
    property: "remaining"
    from: 1
    to: 0
    duration: root.timeout
    running: root.popup && root.timeout > 0 && !root.lock.retained
    paused: running && (root.hovered || root.above || root.unseen)
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
