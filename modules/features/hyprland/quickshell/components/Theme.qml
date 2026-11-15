pragma Singleton

import QtQuick
import Quickshell
import qs.nix

// Every colour and size the menus and notifications draw with.
Singleton {
  readonly property color bg: Colors.bg1
  readonly property color selected: Colors.bg3
  readonly property color border: Colors.bg3
  readonly property color fg: Colors.fg
  readonly property color fgDim: Colors.gray
  readonly property color fgSoft: Colors.grayLight
  readonly property color raised: Colors.bg2
  readonly property color accent: Colors.primaryColor
  readonly property color urgent: Colors.red

  // Sizes are written for 1920×1080; this enlarges them all.
  readonly property real scale: 1.25

  function px(size) {
    return Math.round(size * scale);
  }

  readonly property string fontFamily: "Adwaita Sans"
  // For ✕ and ▾, which Adwaita Sans lacks.
  readonly property string glyphFamily: "Adwaita Mono"
  readonly property int fontSize: px(19)
  readonly property int subtitleSize: px(14)

  readonly property int cardWidth: px(640)
  readonly property int cardRadius: px(12)
  readonly property int cardPadding: px(12)
  readonly property int rowHeight: px(56)
  readonly property int iconSize: px(28)
  readonly property int maxRows: 7

  readonly property int smallSize: px(12)
  readonly property int summarySize: px(16)
  readonly property int notificationWidth: px(400)
  readonly property int notificationGap: px(10)
  readonly property int imageSize: px(48)
}
