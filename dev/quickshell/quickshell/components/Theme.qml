pragma Singleton

import QtQuick
import Quickshell

// Every colour and size the menus draw with. The colours are copied from
// `palettes.ui` in the main flake.
Singleton {
  readonly property color bg: "#1c1c1c"
  readonly property color selected: "#3a3a3a"
  readonly property color border: "#3a3a3a"
  readonly property color fg: "#f1f1f1"
  readonly property color fgDim: "#818589"

  readonly property string fontFamily: "Adwaita Sans"
  readonly property int fontSize: 19
  readonly property int subtitleSize: 14

  readonly property int cardWidth: 640
  readonly property int cardRadius: 12
  readonly property int cardPadding: 12
  readonly property int rowHeight: 56
  readonly property int iconSize: 28
  readonly property int maxRows: 7
}
