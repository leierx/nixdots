import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.common

QtObject {
  id: root

  required property Notification notification
  required property string screen
  property date time: new Date()
  property bool popup: false
  // The popup under the pointer holds the timeout.
  property bool hovered: false
  // So does one below the screen's edge, until there is room for it, or one with no monitor on to show it.
  property bool waiting: false
  readonly property bool unseen: waiting || !Screens.has(screen)

  readonly property bool critical: notification.urgency === NotificationUrgency.Critical
  readonly property string appIcon: Notifs.appIcon(notification)
  readonly property string body: Notifs.cleanBody(notification.body)
  readonly property NotificationAction defaultAction: Array.from(notification.actions).find(a => a.identifier === "default") ?? null
  readonly property var buttons: Array.from(notification.actions).filter(a => a.identifier !== "default")
  readonly property var progress: notification.hints.value

  readonly property int timeout: {
    if (critical) return 0;
    const requested = notification.expireTimeout;
    return requested < 0 ? Notifs.defaultTimeout : requested;
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
    object: root.notification
    locked: true
  }

  // Hovering restarts the countdown rather than resuming it.
  property Timer timer: Timer {
    interval: root.timeout
    running: root.popup && root.timeout > 0 && !root.hovered && !root.unseen && !root.lock.retained
    onTriggered: root.popup = false
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
      Qt.callLater(root.reshow);
    }
  }
}
