pragma Singleton

import QtQuick
import Quickshell
import qs.nix

// Every colour and size the menus draw with.
Singleton {
  readonly property color bg: Colors.bg1
  readonly property color selected: Colors.bg3
  readonly property color border: Colors.bg3
  readonly property color fg: Colors.fg
  readonly property color fgDim: Colors.gray

  // Sizes are written for 1920×1080; this enlarges them all.
  readonly property real scale: 1.25

  function px(size) {
    return Math.round(size * scale);
  }

  readonly property string fontFamily: "Adwaita Sans"
  readonly property int fontSize: px(19)
  readonly property int subtitleSize: px(14)

  readonly property int cardWidth: px(640)
  readonly property int cardRadius: px(12)
  readonly property int cardPadding: px(12)
  readonly property int rowHeight: px(56)
  readonly property int iconSize: px(28)
  readonly property int maxRows: 7
}
