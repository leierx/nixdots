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
