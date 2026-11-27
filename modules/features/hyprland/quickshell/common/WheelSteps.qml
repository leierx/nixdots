import QtQuick

QtObject {
  id: root

  property real pending: 0

  function steps(event: var): int {
    const delta = event.angleDelta.y || event.pixelDelta.y;
    // Left over from the other way, a part notch would eat the next one.
    if (delta * root.pending < 0) root.pending = 0;
    root.pending += delta;
    const steps = Math.trunc(root.pending / 120);
    root.pending -= steps * 120;
    return steps;
  }
}
