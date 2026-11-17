import QtQuick

MouseArea {
  id: root

  // Its x is bound to `distance`; hold() and slideAway() take it over.
  property Item target: null
  readonly property int threshold: 70
  property bool swipeEnabled: true
  property bool dragging: false
  property real distance: 0
  property point start
  property bool dragged: false
  // In px per ms, from the last two moves.
  property real velocity: 0
  property real lastX: 0
  property real lastTime: 0

  signal swiped(bool left)
  signal tapped(int button)
  signal gone()

  // Leaves the target where the swipe let go, unbound from `distance`.
  function hold(): void {
    root.target.x = root.target.x;
  }

  function slideAway(left: bool): void {
    root.hold();
    away.to = (left ? -1 : 1) * (root.width + 20);
    away.start();
  }

  acceptedButtons: Qt.LeftButton | Qt.RightButton
  preventStealing: dragging

  onPressed: mouse => {
    start = Qt.point(mouse.x, mouse.y);
    dragged = false;
    velocity = 0;
    lastX = mouse.x;
    lastTime = Date.now();
  }
  onPositionChanged: mouse => {
    if (!swipeEnabled || !(pressedButtons & Qt.LeftButton)) return;
    const dx = mouse.x - start.x;
    if (!dragging && Math.abs(dx) > 8 && Math.abs(dx) > Math.abs(mouse.y - start.y)) {
      // From here, so the card does not jump the 8 px it took to tell a drag from a click.
      start = Qt.point(mouse.x, mouse.y);
      dragging = true;
    }
    if (!dragging) return;
    // Over at least a frame, as moves arrive a millisecond apart.
    const now = Date.now();
    if (now - lastTime >= 16) {
      velocity = (mouse.x - lastX) / (now - lastTime);
      lastX = mouse.x;
      lastTime = now;
    }
    distance = mouse.x - start.x;
  }
  onReleased: {
    if (!dragging) return;
    dragged = true;
    // A pointer held still before letting go has stopped, whatever it did before.
    if (Date.now() - lastTime > 100) velocity = 0;
    const flung = Math.abs(velocity) > 0.5 && Math.sign(velocity) === Math.sign(distance);
    // Before the drag ends, so a dismissed target is held where it was let go.
    if (Math.abs(distance) > threshold || flung) swiped(distance < 0);
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

  // Fast first, carrying on from the drag rather than starting again from rest.
  NumberAnimation {
    id: away

    target: root.target
    property: "x"
    duration: 220
    easing.type: Easing.OutCubic
    onFinished: root.gone()
  }
}
