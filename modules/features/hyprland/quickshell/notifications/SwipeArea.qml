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

  acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
  preventStealing: dragging

  onPressed: mouse => {
    start = Qt.point(mouse.x, mouse.y);
    dragged = false;
  }
  onPositionChanged: mouse => {
    if (!swipeEnabled || !(pressedButtons & Qt.LeftButton)) return;
    const dx = mouse.x - start.x;
    if (!dragging && Math.abs(dx) > 8 && Math.abs(dx) > Math.abs(mouse.y - start.y)) dragging = true;
    if (dragging) distance = dx;
  }
  onReleased: {
    if (!dragging) return;
    dragged = true;
    // Before the drag ends, so a dismissed target is held where it was let go.
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

  NumberAnimation {
    id: away

    target: root.target
    property: "x"
    duration: 200
    easing.type: Easing.InCubic
    onFinished: root.gone()
  }
}
