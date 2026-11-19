pragma Singleton

import QtQuick
import Quickshell
import qs.nix

Singleton {
  id: root

  // Shell surfaces are views, the darkest of libadwaita's backgrounds.
  readonly property color bg: Colors.view_bg_color
  readonly property color fg: Colors.view_fg_color
  readonly property color fgStrong: overlay(0.8)
  readonly property color fgDim: overlay(0.55)
  readonly property color fgFaint: overlay(0.16)
  // GNOME Shell's panel black.
  readonly property color panel: Colors.dark_5
  readonly property color accentBg: Colors.accent_bg_color
  readonly property color accentFg: Colors.accent_fg_color
  // For text and lines on bg, where accentBg is too dark.
  readonly property color accent: Colors.accent_color
  readonly property color destructiveBg: Colors.destructive_bg_color
  readonly property color destructive: Colors.destructive_color
  readonly property color warning: Colors.warning_color
  readonly property color success: Colors.success_color
  // A recording light's red.
  readonly property color recording: Colors.red_2
  // Caffeine's cup.
  readonly property color coffee: Colors.brown_1
  // The bell's, while notifications wait.
  readonly property color bell: Colors.yellow_3
  readonly property color nixosLight: "#7ebae4"
  readonly property color nixosDark: "#5277c3"

  readonly property color outline: overlay(0.07)
  readonly property color border: overlay(0.15)
  readonly property color card: Colors.card_bg_color
  readonly property color cardHover: overlay(0.11)
  // A critical notification in the center, marked by its fill rather than an outline.
  readonly property color criticalCard: Qt.rgba(Colors.destructive_bg_color.r, Colors.destructive_bg_color.g, Colors.destructive_bg_color.b, 0.16)
  readonly property color criticalCardHover: Qt.rgba(Colors.destructive_bg_color.r, Colors.destructive_bg_color.g, Colors.destructive_bg_color.b, 0.24)
  readonly property color hover: overlay(0.07)
  readonly property color selected: overlay(0.10)
  readonly property color button: overlay(0.10)
  readonly property color buttonHover: overlay(0.15)
  readonly property color buttonChecked: overlay(0.25)
  readonly property color trough: overlay(0.15)
  readonly property color slider: Qt.tint(Colors.view_bg_color, overlay(0.8))
  // libadwaita's window shadow: a wide soft one and a tight one.
  readonly property color shadow: Qt.rgba(0, 0, 0, 0.15)
  readonly property color shadowTight: Qt.rgba(0, 0, 0, 0.1)
  readonly property color backdrop: Qt.rgba(0, 0, 0, 0.88)

  readonly property font body: Qt.font({ family: "Adwaita Sans", pointSize: 11 })
  readonly property font heading: Qt.font({ family: "Adwaita Sans", pointSize: 11, weight: Font.Bold })
  readonly property font caption: Qt.font({ family: "Adwaita Sans", pointSize: 9 })
  readonly property font captionHeading: Qt.font({ family: "Adwaita Sans", pointSize: 9, weight: Font.Bold })
  readonly property font title4: Qt.font({ family: "Adwaita Sans", pointSize: 13, weight: Font.Bold })
  readonly property font title2: Qt.font({ family: "Adwaita Sans", pointSize: 15, weight: Font.ExtraBold })

  readonly property int smallRadius: 6
  readonly property int buttonRadius: 9
  readonly property int cardRadius: 12
  readonly property int windowRadius: 15

  // The body font's size in px, the unit GNOME Shell sizes its panels in.
  readonly property real em: body.pointSize * 96 / 72

  readonly property int gap: 10
  // Inside cards, as libadwaita pads its boxed rows.
  readonly property int padding: 12
  // How long a hover or press takes to change a colour.
  readonly property int fade: 150

  // The foreground over whatever lies below, as libadwaita mixes currentColor.
  function overlay(alpha: real): color {
    return Qt.rgba(root.fg.r, root.fg.g, root.fg.b, alpha);
  }
}
