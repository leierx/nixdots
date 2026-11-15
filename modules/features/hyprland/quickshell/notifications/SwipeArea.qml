import QtQuick
import qs.common

// Tells a sideways drag from a click. Once the pointer has moved sideways,
// `distance` follows it and the list stops scrolling; letting go past
// `threshold` emits `swiped`. Clicks without a drag emit `tapped`.
MouseArea {
  id: root

  readonly property int threshold: Theme.px(70)
  property bool swipeEnabled: true
  property bool dragging: false
  property real distance: 0
  property point start
  property bool dragged: false

  signal swiped(bool left)
  signal tapped(int button)

  acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
  preventStealing: dragging

  onPressed: mouse => {
    start = Qt.point(mouse.x, mouse.y);
    dragged = false;
  }
  onPositionChanged: mouse => {
    if (!swipeEnabled || !(pressedButtons & Qt.LeftButton)) return;
    const dx = mouse.x - start.x;
    if (!dragging && Math.abs(dx) > Theme.px(8) && Math.abs(dx) > Math.abs(mouse.y - start.y)) dragging = true;
    if (dragging) distance = dx;
  }
  onReleased: {
    if (!dragging) return;
    dragged = true;
    // Before the drag ends, so a dismissed card is already sliding away.
    if (Math.abs(distance) > threshold) swiped(distance < 0);
    dragging = false;
    distance = 0;
  }
  onCanceled: {
    dragging = false;
    distance = 0;
  }
  onClicked: mouse => {
    if (!dragged) tapped(mouse.button);
  }
}
