import QtQuick
import Quickshell
import Quickshell.Wayland

// A popover off the bar: `shown` eases in and out over popupTime, clicks and the keyboard go elsewhere while it closes, and `hidden` says it has gone.
Overlay {
  id: root

  readonly property bool open: Panels.active === name
  property real shown: 0

  signal hidden()

  onOpenChanged: {
    (open ? closing : opening).stop();
    // Closed before it moved, it has nothing to animate, and would never report itself hidden.
    if (!open && shown === 0) Qt.callLater(root.hideClosed);
    else (open ? opening : closing).start();
  }
  onShownChanged: if (shown === 0 && !open) hidden()
  // A window Hyprland has closed stays closed, so the next open needs a new one.
  onClosed: hidden()
  Component.onCompleted: {
    if (open) opening.start();
    else Qt.callLater(root.hideClosed);
  }

  function hideClosed(): void {
    if (!root.open) root.hidden();
  }

  mask: open ? null : nothing
  WlrLayershell.keyboardFocus: open ? root.keyboard : WlrKeyboardFocus.None

  Region {
    id: nothing
  }

  // Not a Behavior: one whose duration follows `open` may start before that duration updates.
  NumberAnimation {
    id: opening

    target: root
    property: "shown"
    to: 1
    duration: Theme.popupTime
    easing.type: Easing.OutQuad
  }

  NumberAnimation {
    id: closing

    target: root
    property: "shown"
    to: 0
    duration: Theme.popupTime
    easing.type: Easing.OutQuad
  }
}
