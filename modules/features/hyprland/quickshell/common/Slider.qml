import QtQuick

Item {
  id: slider

  property real value: 0
  // The top of the range: past 1 while the level is beyond 100 %, which is marked then.
  property real maximum: 1
  property bool dim: false
  // The range as a drag began, so the slider does not rescale under it.
  property real heldMaximum: 1
  readonly property real span: drag.pressed ? heldMaximum : Math.max(1, maximum)
  readonly property real fraction: Math.max(0, Math.min(1, value / span))
  // Where a drag began, which Escape puts back; a drag Escape cancelled moves nothing more until released.
  property real startValue: 0
  property bool cancelled: false

  signal moved(real value)
  signal stepped(int notches)

  implicitHeight: 26

  Keys.onEscapePressed: event => {
    if (!drag.pressed || slider.cancelled) {
      event.accepted = false;
      return;
    }
    slider.cancelled = true;
    slider.moved(slider.startValue);
  }

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 6
    radius: height / 2
    color: Theme.trough

    Rectangle {
      width: parent.width * slider.fraction
      height: parent.height
      radius: parent.radius
      color: slider.dim ? Theme.fgDim : Theme.accentBg

      Behavior on color {
        ColorAnimation {
          duration: Theme.fade
        }
      }
    }
  }

  // 100 %, while the range goes past it.
  Rectangle {
    visible: slider.span > 1
    x: (slider.width - 16) / slider.span + 8 - width / 2
    anchors.verticalCenter: parent.verticalCenter
    width: 2
    height: 14
    radius: width / 2
    color: Theme.fgDim
  }

  Rectangle {
    x: slider.fraction * (slider.width - width)
    anchors.verticalCenter: parent.verticalCenter
    width: 16
    height: 16
    radius: height / 2
    color: Theme.slider
    scale: drag.pressed ? 1.1 : 1

    Behavior on scale {
      NumberAnimation {
        duration: Theme.tap
      }
    }
  }

  MouseArea {
    id: drag

    anchors.fill: parent
    // Set from the slider, which reads its own; a disabled ancestor leaves it reading true.
    enabled: slider.enabled
    cursorShape: !enabled ? Qt.ArrowCursor : pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
    onPressed: mouse => {
      slider.forceActiveFocus();
      slider.cancelled = false;
      slider.startValue = slider.value;
      slider.heldMaximum = Math.max(1, slider.maximum);
      slider.moved(Math.max(0, Math.min(1, mouse.x / width)) * slider.heldMaximum);
    }
    onPositionChanged: mouse => {
      if (pressed && !slider.cancelled) slider.moved(Math.max(0, Math.min(1, mouse.x / width)) * slider.span);
    }
    onWheel: event => {
      const steps = notches.steps(event);
      if (steps !== 0) slider.stepped(steps);
    }
  }

  WheelSteps {
    id: notches
  }
}
