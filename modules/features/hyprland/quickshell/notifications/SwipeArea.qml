import QtQuick
import qs.common

MouseArea {
  id: root

  // Its x is this area's to set.
  property Item target: null
  // Popups only leave towards the screen's edge.
  property bool rightOnly: false
  property bool swipeEnabled: true
  readonly property int threshold: 70
  property bool dragging: false
  property point start
  property bool dragged: false
  // In px per ms, over at least a frame.
  property real velocity: 0
  property real lastX: 0
  property real lastTime: 0
  // The cursor while not dragging; a hand where the click opens something.
  property var restCursor: Qt.ArrowCursor
  property var finished: null

  signal swiped(bool left)
  signal tapped()

  // `done` runs once the target is off the edge.
  function slideAway(left: bool, done: var): void {
    back.stop();
    root.finished = done ?? null;
    away.to = (left ? -1 : 1) * (root.width + 20);
    away.start();
  }

  // Back in place, as a notification that arrived while it slid keeps what it slid away from.
  function restore(): void {
    if (target && target.x !== 0 && !away.running && !dragging) back.start();
  }

  function finish(): void {
    const done = root.finished;
    root.finished = null;
    done?.();
  }

  // Gone mid-slide, its panel closed or its monitor unplugged, it still dismisses what it was sliding away.
  Component.onDestruction: finish()

  // The HIG keeps the secondary click for a menu, never another way to dismiss.
  acceptedButtons: Qt.LeftButton
  preventStealing: dragging
  cursorShape: dragging ? Qt.ClosedHandCursor : restCursor

  onPressed: mouse => {
    start = Qt.point(mouse.x, mouse.y);
    dragged = false;
    velocity = 0;
    lastX = mouse.x;
    lastTime = Date.now();
  }
  onPositionChanged: mouse => {
    if (!swipeEnabled || away.running || !(pressedButtons & Qt.LeftButton)) return;
    const dx = mouse.x - start.x;
    if (!dragging && Math.abs(dx) > 8 && Math.abs(dx) > Math.abs(mouse.y - start.y)) {
      // From here, so the card does not jump the 8 px it took to tell a drag from a click.
      start = Qt.point(mouse.x, mouse.y);
      back.stop();
      dragging = true;
    }
    if (!dragging) return;
    const now = Date.now();
    if (now - lastTime >= 16) {
      velocity = (mouse.x - lastX) / (now - lastTime);
      lastX = mouse.x;
      lastTime = now;
    }
    target.x = rightOnly ? Math.max(0, mouse.x - start.x) : mouse.x - start.x;
  }
  onReleased: {
    if (!dragging) return;
    dragged = true;
    dragging = false;
    // A pointer held still before letting go has stopped, whatever it did before.
    if (Date.now() - lastTime > 100) velocity = 0;
    const distance = target.x;
    const flung = Math.abs(velocity) > 0.5 && Math.sign(velocity) === Math.sign(distance);
    if (distance !== 0 && (Math.abs(distance) > threshold || flung)) swiped(distance < 0);
    if (!away.running) back.start();
  }
  onCanceled: {
    dragging = false;
    back.start();
  }
  onClicked: mouse => {
    if (!dragged) tapped();
  }

  // Fast first, carrying on from the drag rather than starting again from rest.
  NumberAnimation {
    id: away

    target: root.target
    property: "x"
    duration: Theme.popupTime
    easing.type: Easing.OutQuad
    onFinished: root.finish()
  }

  NumberAnimation {
    id: back

    target: root.target
    property: "x"
    to: 0
    duration: Theme.popupTime
    easing.type: Easing.OutQuad
  }
}
