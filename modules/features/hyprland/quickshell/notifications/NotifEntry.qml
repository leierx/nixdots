import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
  id: root

  required property Notification notification
  required property string screen
  property date time: new Date()
  property bool popup: false
  // Set by the popup under the pointer, which holds the timeout.
  property bool hovered: false

  readonly property bool critical: notification.urgency === NotificationUrgency.Critical
  readonly property string appIcon: Notifs.appIcon(notification)
  readonly property string body: Notifs.cleanBody(notification.body)
  readonly property NotificationAction defaultAction: notification.actions.find(a => a.identifier === "default") ?? null
  readonly property var buttons: notification.actions.filter(a => a.identifier !== "default")
  readonly property bool clickDismisses: !defaultAction && notification.actions.length <= 1
  readonly property var progress: notification.hints.value

  // 0 keeps the popup until it is dismissed.
  readonly property int timeout: {
    if (critical) return 0;
    const requested = notification.expireTimeout;
    return requested < 0 ? Notifs.defaultTimeout : requested;
  }

  function reshow() {
    time = new Date();
    popup = Notifs.wantsPopup(critical);
    if (timer.running) timer.restart();
  }

  onPopupChanged: {
    // A popup removed under the pointer never reports it gone.
    if (!popup) hovered = false;
    // Transient notifications stay out of the history.
    if (!popup && notification.transient) notification.expire();
  }

  // Keeps the closed notification readable while the views slide it away.
  property RetainableLock lock: RetainableLock {
    object: root.notification
    locked: true
  }

  // Hovering restarts the countdown rather than resuming it.
  property Timer timer: Timer {
    interval: root.timeout
    running: root.popup && root.timeout > 0 && !root.hovered && !root.lock.retained
    onTriggered: root.popup = false
  }

  // An app replacing its notification updates it in place.
  property Connections updates: Connections {
    target: root.notification

    function onSummaryChanged() {
      root.reshow();
    }

    function onBodyChanged() {
      root.reshow();
    }
  }
}
