import QtQuick

// Whole notches, positive up: a touchpad's small steps add up to them, and what is left over waits for the next.
QtObject {
  id: root

  property real pending: 0

  function steps(event: var): int {
    root.pending += event.angleDelta.y || event.pixelDelta.y;
    const steps = Math.trunc(root.pending / 120);
    root.pending -= steps * 120;
    return steps;
  }
}
