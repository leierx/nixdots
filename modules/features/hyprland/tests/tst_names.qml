import QtQuick
import QtTest
import "../quickshell/controls/names.js" as Names

TestCase {
  name: "Names"

  function test_one_line() {
    compare(Names.clean("Cafe\nFree\r\tWifi"), "Cafe Free Wifi");
    compare(Names.clean("Cafe\u2028Free\u2029Wifi"), "Cafe Free Wifi");
    compare(Names.clean("\u0085Cafe\u0000"), "Cafe");
  }

  function test_invisible_and_flipping_marks() {
    compare(Names.clean("ab\u202ecd\u200b\u2066ef\ufeff\u061c"), "abcdef");
  }

  function test_not_a_string() {
    compare(Names.clean(null), "");
    compare(Names.clean(undefined), "");
    compare(Names.clean(42), "42");
  }

  function test_length() {
    compare(Names.clean("x".repeat(1000)).length, 300);
  }
}
