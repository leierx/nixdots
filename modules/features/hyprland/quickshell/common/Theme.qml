pragma Singleton

import QtQuick
import Quickshell
import qs.nix

// The colours, fonts and spacing every part of the shell draws with. Sizes
// that belong to one part live in that part.
Singleton {
  readonly property color bg: Colors.bg1
  readonly property color raised: Colors.bg2
  readonly property color selected: Colors.bg3
  // Hover on something already selected.
  readonly property color highlight: Colors.bg4
  readonly property color border: Colors.bg3
  readonly property color fg: Colors.fg
  readonly property color fgDim: Colors.gray
  readonly property color fgSoft: Colors.grayLight
  readonly property color accent: Colors.primaryColor
  readonly property color urgent: Colors.red

  // Sizes are written for 1920×1080; this enlarges them all.
  readonly property real scale: 1.25

  function px(size) {
    return Math.round(size * scale);
  }

  readonly property string fontFamily: "Adwaita Sans"
  // For ▾ and ▴, which Adwaita Sans lacks.
  readonly property string glyphFamily: "Adwaita Mono"
  readonly property int fontLarge: px(19)
  readonly property int fontTitle: px(16)
  readonly property int fontBody: px(14)
  readonly property int fontSmall: px(12)

  readonly property int radius: px(12)
  readonly property int padding: px(12)
  // Between a window and the screen's edge or the bar.
  readonly property int gap: px(10)
}
