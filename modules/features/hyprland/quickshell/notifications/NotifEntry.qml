import QtQuick
import Quickshell.Services.Notifications

// What the shell keeps about one notification besides the notification
// itself: when it arrived, which monitor its popup is on, and whether that
// popup is still showing.
QtObject {
  id: root

  required property Notification notification
  required property string screen
  property date time: new Date()
  property bool popup: false
  // Set by the popup while the pointer is over it, which holds the timeout.
  property bool hovered: false

  readonly property bool critical: notification?.urgency === NotificationUrgency.Critical

  // In milliseconds; 0 keeps the popup until it is dismissed.
  readonly property int timeout: {
    if (!notification || critical) return 0;
    const requested = notification.expireTimeout;
    return requested < 0 ? Notifs.defaultTimeout : requested;
  }

  // Shows the popup again, for a notification an app has just updated.
  function reshow() {
    time = new Date();
    popup = Notifs.wantsPopup(critical);
    schedule();
  }

  // Hovering restarts the countdown rather than resuming it.
  function schedule() {
    if (popup && timeout > 0 && !hovered) timer.restart();
    else timer.stop();
  }

  onPopupChanged: {
    // Transient notifications stay out of the history.
    if (!popup && notification?.transient) notification.expire();
    else schedule();
  }
  onHoveredChanged: schedule()
  Component.onCompleted: schedule()

  property Timer timer: Timer {
    interval: root.timeout
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
