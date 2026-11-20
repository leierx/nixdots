import QtQuick

Item {
  id: slider

  property real value: 0
  property bool dim: false

  signal moved(real value)
  signal stepped(int notches)

  implicitHeight: 26

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 6
    radius: height / 2
    color: Theme.trough

    Rectangle {
      width: parent.width * Math.max(0, Math.min(1, slider.value))
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

  Rectangle {
    x: Math.max(0, Math.min(1, slider.value)) * (slider.width - width)
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
    onPressed: mouse => slider.moved(Math.max(0, Math.min(1, mouse.x / width)))
    onPositionChanged: mouse => {
      if (pressed) slider.moved(Math.max(0, Math.min(1, mouse.x / width)));
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
