import QtQuick
import QtTest
import "../quickshell/launcher/search.js" as Search

TestCase {
  name: "LauncherSearch"

  function score(query, text, loose) {
    return Search.scoreFields(Search.words(query), [[1, text, loose]]);
  }

  function test_no_words_keep_order() {
    compare(score("", "anything"), 0);
    compare(score("  ", ""), 0);
  }

  function test_no_match() {
    compare(score("zzz", "Firefox"), -1);
    compare(score("fire", ""), -1);
    compare(score("ffx", "Firefox"), -1);
  }

  function test_kinds_ranked() {
    const start = score("fire", "Firefox");
    const word = score("fox", "Fire Fox");
    const inside = score("fox", "Firefox");
    const loose = score("ffx", "Firefox", true);
    const slip = score("firfeox", "Firefox");
    verify(start > word && word > inside && inside > loose && loose > slip && slip > 0, [start, word, inside, loose, slip]);
  }

  function test_shorter_wins_a_tie() {
    verify(score("firefox", "Firefox") > score("firefox", "Firefox Developer Edition"));
  }

  function test_every_word_must_match() {
    verify(score("fire dev", "Firefox Developer Edition") > 0);
    compare(score("fire zzz", "Firefox Developer Edition"), -1);
  }

  function test_slips() {
    for (const typed of ["firfox", "firefx", "firefoxx", "fierfox", "firebox"]) verify(score(typed, "Firefox") > 0, typed);
    compare(score("frx", "Firefox"), -1);
    compare(score("fiefx", "Firefox"), -1);
  }

  function test_best_field_weighted() {
    const typed = Search.words("term");
    verify(Search.scoreFields(typed, [[1, "Terminal"], [0.5, "terminal emulator"]]) > Search.scoreFields(typed, [[1, "Wezterm"], [0.5, "terminal emulator"]]));
  }

  function test_mark() {
    compare(Search.mark("fire", "Firefox"), "<b>Fire</b>fox");
    compare(Search.mark("ffx", "Firefox", true), "<b>F</b>ire<b>f</b>o<b>x</b>");
    compare(Search.mark("ffx", "Firefox", false), "Firefox");
    compare(Search.mark("firfeox", "Firefox"), "<b>Firefox</b>");
    compare(Search.mark("a", "a <b>"), "<b>a</b>&nbsp;&lt;b&gt;");
  }
}
