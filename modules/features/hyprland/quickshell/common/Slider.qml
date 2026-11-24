import QtQuick

Item {
  id: slider

  property real value: 0
  // The top of the range: past 1 while the level is beyond 100 %, which is marked then.
  property real maximum: 1
  property bool dim: false
  property color fill: Theme.accentBg
  // The range as a drag began, so the slider does not rescale under it.
  property real heldMaximum: 1
  readonly property real span: drag.pressed ? heldMaximum : Math.max(1, maximum)
  readonly property real fraction: Math.max(0, Math.min(1, value / span))
  // What it draws: a change from elsewhere (a key, another app) eases as the OSD does; a drag follows the pointer.
  property real drawn: fraction

  Behavior on drawn {
    enabled: !drag.pressed

    NumberAnimation {
      duration: Theme.levelTime
      easing.type: Easing.OutQuad
    }
  }
  // Where a drag began, which Escape puts back; a drag Escape cancelled moves nothing more until released.
  property real startValue: 0
  property bool cancelled: false

  // The mouse's, unless something (the gallery) holds a look.
  property bool hovered: drag.containsMouse

  signal moved(real value)
  signal stepped(int notches)

  implicitHeight: 26
  opacity: enabled ? 1 : 0.5

  Behavior on opacity {
    NumberAnimation {
      duration: Theme.quickTime
      easing.type: Easing.OutQuad
    }
  }

  activeFocusOnTab: enabled || activeFocus
  Keys.onLeftPressed: slider.stepped(-1)
  Keys.onRightPressed: slider.stepped(1)

  Keys.onEscapePressed: event => {
    if (!drag.pressed || slider.cancelled) {
      event.accepted = false;
      return;
    }
    slider.cancelled = true;
    slider.moved(slider.startValue);
  }

  // Shell's barLevel: a 4 px trough, the level in the accent up to 100 % and red past it.
  readonly property real inner: width - 16
  readonly property real full: 8 + inner / span
  readonly property real at: 8 + inner * drawn

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 4
    radius: height / 2
    color: Theme.troughBg

    Rectangle {
      width: Math.min(slider.at, slider.span > 1 ? slider.full - 0.5 : slider.at)
      height: parent.height
      radius: parent.radius
      color: slider.dim ? Theme.fgDim : slider.fill

      Behavior on color {
        ColorAnimation {
          duration: Theme.quickTime
          easing.type: Easing.OutQuad
        }
      }
    }

    Rectangle {
      visible: slider.at > slider.full + 0.5
      x: slider.full + 0.5
      width: slider.at - x
      height: parent.height
      color: Theme.destructiveBg
    }
  }

  // 100 %, while the range goes past it: a mark in the knob's colour below it, a gap above.
  Rectangle {
    visible: slider.span > 1 && slider.at <= slider.full
    x: slider.full - 0.5
    anchors.verticalCenter: parent.verticalCenter
    width: 1
    height: 4
    color: Theme.sliderKnob
  }

  Rectangle {
    x: slider.at - width / 2
    anchors.verticalCenter: parent.verticalCenter
    width: 16
    height: 16
    radius: height / 2
    color: slider.hovered || drag.pressed ? Theme.fg : Theme.sliderKnob
  }

  MouseArea {
    id: drag

    anchors.fill: parent
    hoverEnabled: true
    // Set from the slider, which reads its own; a disabled ancestor leaves it reading true.
    enabled: slider.enabled
    cursorShape: !enabled ? Qt.ArrowCursor : pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
    onPressed: mouse => {
      slider.forceActiveFocus();
      slider.cancelled = false;
      slider.startValue = slider.value;
      slider.heldMaximum = Math.max(1, slider.maximum);
      slider.moved(Math.max(0, Math.min(1, (mouse.x - 8) / slider.inner)) * slider.heldMaximum);
    }
    onPositionChanged: mouse => {
      if (pressed && !slider.cancelled) slider.moved(Math.max(0, Math.min(1, (mouse.x - 8) / slider.inner)) * slider.span);
    }
    onWheel: event => {
      const steps = notches.steps(event);
      if (steps !== 0) slider.stepped(steps);
    }
  }

  WheelSteps {
    id: notches
  }

  FocusRing {
    corner: slider.height / 2
    on: slider.activeFocus
  }
}
