import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// What the shell keeps about one notification besides the notification
// itself: when it arrived, which monitor its popup is on, and whether that
// popup is still showing, plus what every view reads off the notification.
QtObject {
  id: root

  required property Notification notification
  required property string screen
  property date time: new Date()
  property bool popup: false
  // Set by the popup while the pointer is over it, which holds the timeout.
  property bool hovered: false

  readonly property bool critical: notification.urgency === NotificationUrgency.Critical
  readonly property string appIcon: Notifs.appIcon(notification)
  readonly property NotificationAction defaultAction: notification.actions.find(a => a.identifier === "default") ?? null
  // The actions shown as buttons.
  readonly property var buttons: notification.actions.filter(a => a.identifier !== "default")
  // A percentage, if the app sends one.
  readonly property var progress: notification.hints.value

  // In milliseconds; 0 keeps the popup until it is dismissed.
  readonly property int timeout: {
    if (critical) return 0;
    const requested = notification.expireTimeout;
    return requested < 0 ? Notifs.defaultTimeout : requested;
  }

  // Shows the popup again, for a notification an app has just updated.
  function reshow() {
    time = new Date();
    popup = Notifs.wantsPopup(critical);
    if (timer.running) timer.restart();
  }

  // Transient notifications stay out of the history.
  onPopupChanged: {
    if (!popup && notification.transient) notification.expire();
  }

  // Keeps the notification readable once it has closed, while the views slide
  // it away; it goes with this entry.
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

  // An app replacing its notification updates this object in place.
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
