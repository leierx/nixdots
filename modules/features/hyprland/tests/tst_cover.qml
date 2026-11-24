import QtQuick
import QtTest
import "../quickshell/common/cover.js" as Cover

TestCase {
  name: "Cover"

  function luminance(hex) {
    const channel = i => {
      const c = parseInt(hex.slice(1 + 2 * i, 3 + 2 * i), 16) / 255;
      return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    };
    return 0.2126 * channel(0) + 0.7152 * channel(1) + 0.0722 * channel(2);
  }

  function test_nothing_to_go_on_is_null() {
    compare(Cover.cover([]), null);
    compare(Cover.cover(undefined), null);
  }

  function test_a_black_cover_with_a_bright_centre_takes_the_centre() {
    const black = Qt.rgba(0.03, 0.03, 0.05, 1);
    const tint = Cover.cover([black, black, black, black, black, black, black, Qt.rgba(1, 0.25, 0.64, 1)]);
    verify(tint.accent !== "");
    verify(parseInt(tint.card.slice(1, 3), 16) > parseInt(tint.card.slice(5, 7), 16), tint.card);
  }

  function test_a_grey_cover_keeps_white_controls() {
    const paper = Qt.rgba(0.93, 0.92, 0.88, 1);
    const tint = Cover.cover([paper, paper, paper, paper, paper, paper, Qt.rgba(0.1, 0.1, 0.1, 1), Qt.rgba(0.5, 0.5, 0.5, 1)]);
    compare(tint.accent, "");
    verify(tint.card !== "");
  }

  function test_white_reads_on_every_hue_and_dark_on_its_accent() {
    for (const color of [Qt.rgba(1, 0.85, 0.1, 1), Qt.rgba(0.2, 0.5, 1, 1), Qt.rgba(0.1, 0.8, 0.3, 1), Qt.rgba(0.9, 0.1, 0.1, 1), Qt.rgba(0.6, 0.2, 0.9, 1)]) {
      const tint = Cover.cover([color]);
      verify(1.05 / (luminance(tint.card) + 0.05) >= 7, `${color} gives ${tint.card}`);
      verify((luminance(tint.accentPressed) + 0.05) / 0.05 >= 7, `${color} gives ${tint.accentPressed}`);
    }
  }
}
