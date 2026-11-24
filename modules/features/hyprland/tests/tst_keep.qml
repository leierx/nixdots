import QtQuick
import QtTest
import "../quickshell/common/keep.js" as Keep

TestCase {
  name: "Keep"

  QtObject {
    id: device
  }

  QtObject {
    id: other
  }

  function test_unchanged_rows_stay_the_same_objects() {
    const memo = {};
    const first = Keep.keep(memo, [{ key: "a", title: "A" }, { key: "b", title: "B", parts: [1, { x: 2 }] }], "key");
    const second = Keep.keep(memo, [{ key: "a", title: "A" }, { key: "n", title: "New" }, { key: "b", title: "B", parts: [1, { x: 2 }] }], "key");
    verify(second[0] === first[0]);
    verify(second[2] === first[1]);
    compare(second[1].title, "New");
  }

  function test_changed_rows_are_new() {
    const memo = {};
    const first = Keep.keep(memo, [{ key: "a", title: "A", parts: [1] }], "key");
    const second = Keep.keep(memo, [{ key: "a", title: "A", parts: [2] }], "key");
    verify(second[0] !== first[0]);
    const third = Keep.keep(memo, [{ key: "a", title: "A", parts: [2], more: true }], "key");
    verify(third[0] !== second[0]);
  }

  function test_objects_by_identity() {
    const memo = {};
    const first = Keep.keep(memo, [{ key: "a", target: device }], "key");
    verify(Keep.keep(memo, [{ key: "a", target: device }], "key")[0] === first[0]);
    verify(Keep.keep(memo, [{ key: "a", target: other }], "key")[0] !== first[0]);
  }
}
