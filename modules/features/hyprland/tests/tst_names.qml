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

  function test_fillers_and_tags() {
    compare(Names.clean("\u3164"), "");
    compare(Names.clean("a\u115f\u1160b\uffa0"), "ab");
    compare(Names.clean("flag\udb40\udc67\udb40\udc62\udb40\udc7f"), "flag");
  }

  function test_length_keeps_pairs_whole() {
    const cut = Names.clean("x".repeat(299) + "\ud83d\ude00".repeat(10));
    compare(cut.length, 299);
    compare(Names.clean("x".repeat(298) + "\ud83d\ude00".repeat(10)).length, 300);
  }
}
