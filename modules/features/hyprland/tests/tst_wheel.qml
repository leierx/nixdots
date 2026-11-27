import QtQuick
import QtTest
import "../quickshell/common"

TestCase {
  name: "WheelSteps"

  WheelSteps {
    id: wheel
  }

  function notch(y) {
    return { angleDelta: Qt.point(0, y), pixelDelta: Qt.point(0, 0) };
  }

  function init() {
    wheel.pending = 0;
  }

  function test_whole_notches() {
    compare(wheel.steps(notch(120)), 1);
    compare(wheel.steps(notch(-240)), -2);
  }

  function test_part_notches_add_up() {
    compare(wheel.steps(notch(60)), 0);
    compare(wheel.steps(notch(60)), 1);
  }

  function test_a_part_notch_never_eats_one_the_other_way() {
    compare(wheel.steps(notch(60)), 0);
    compare(wheel.steps(notch(-120)), -1);
    compare(wheel.steps(notch(-60)), 0);
    compare(wheel.steps(notch(120)), 1);
  }

  function test_touchpad_pixels() {
    compare(wheel.steps({ angleDelta: Qt.point(0, 0), pixelDelta: Qt.point(0, 130) }), 1);
  }
}
