import QtQuick

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
