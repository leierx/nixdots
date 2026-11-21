pragma Singleton

import QtQuick
import Quickshell
import qs.nix

// GNOME Shell 51 and libadwaita 1.10 on the darker palette; STYLE.md says where each value comes from.
Singleton {
  id: root

  readonly property color fg: Colors.view_fg_color
  readonly property color fgDim: overlay(0.55)
  readonly property color fgFaint: overlay(0.16)
  readonly property color fgStrong: overlay(0.8)
  readonly property color placeholder: overlay(0.7)

  readonly property color panelBg: Colors.dark_5
  readonly property color popoverBg: Colors.shell_bg_color
  readonly property color popoverBorder: Colors.shell_outer_borders_color
  readonly property color cardBg: Colors.shell_card_bg_color
  readonly property color messageBg: Colors.shell_message_bg_color
  readonly property color messageHoverBg: lighten(Colors.shell_message_bg_color, 0.04)
  readonly property color messageButtonBg: overlay(0.15)
  readonly property color messageButtonHoverBg: overlay(0.3)
  readonly property color messageButtonActiveBg: overlay(0.2)
  readonly property color osdBg: Colors.shell_osd_bg_color
  readonly property color osdBorder: overlay(0.02)
  readonly property color tooltipBg: Qt.rgba(0, 0, 0, 0.9)
  readonly property color tooltipBorder: overlay(0.1)
  readonly property color separator: overlay(0.1)
  readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.2)
  // libadwaita's $toast_bg_color #505053, less 14 as an opaque surface.
  readonly property color toastBg: "#424245"
  readonly property color keycapBg: overlay(0.1)
  readonly property color keycapShade: Colors.card_shade_color

  readonly property color accentBg: Colors.accent_bg_color
  readonly property color accentFg: Colors.accent_fg_color
  readonly property color accentHover: lighten(Colors.accent_bg_color, 0.04)
  readonly property color accentActive: lighten(Colors.accent_bg_color, 0.09)
  // A quick toggle's menu segment and the rule before it, on (st-mix with white) and off.
  readonly property color accentSegmentBg: Qt.tint(Colors.accent_bg_color, Qt.rgba(1, 1, 1, 0.15))
  readonly property color accentSeparator: Qt.tint(Colors.accent_bg_color, Qt.rgba(1, 1, 1, 0.3))
  readonly property color accentSegmentHoverBg: lighten(accentSegmentBg, 0.04)
  readonly property color segmentHoverBg: overlay(0.17)
  readonly property color segmentSeparator: overlay(0.25)
  // A check box's edge off (Shell's .check-box).
  readonly property color checkBorder: overlay(0.15)
  readonly property color headerIconBg: overlay(0.2)
  readonly property color destructiveBg: Colors.destructive_bg_color
  readonly property color destructiveHover: lighten(Colors.destructive_bg_color, 0.04)
  readonly property color destructiveActive: lighten(Colors.destructive_bg_color, 0.09)
  readonly property color destructive: Colors.destructive_color
  readonly property color warning: Colors.warning_color
  readonly property color success: Colors.success_color
  readonly property color recording: Colors.red_2
  readonly property color bell: Colors.yellow_2
  readonly property color inUse: Colors.orange_2

  // Shell's button states as the foreground over the popover, so they hold on any surface.
  readonly property color buttonBg: overlay(0.09)
  readonly property color buttonHoverBg: overlay(0.13)
  readonly property color buttonActiveBg: overlay(0.19)
  readonly property color buttonCheckedBg: overlay(0.18)
  readonly property color buttonCheckedHoverBg: overlay(0.22)
  readonly property color menuHoverBg: overlay(0.13)
  readonly property color menuActiveBg: overlay(0.16)
  // The user's pick over Shell's, which marks the keyboard as it marks hover.
  readonly property color selectedBg: overlay(0.15)
  readonly property color panelHoverBg: overlay(0.17)
  readonly property color panelActiveBg: overlay(0.28)
  readonly property color panelActiveHoverBg: overlay(0.32)
  readonly property color switchBg: overlay(0.15)
  readonly property color switchHoverBg: overlay(0.2)
  readonly property color switchKnob: "#d7d7d8"
  readonly property color troughBg: overlay(0.1)
  readonly property color sliderKnob: "#e8e8e8"
  readonly property color scrollHandle: overlay(0.28)
  // Ours, not Shell's lighter blue: the one accent.
  readonly property color focusRing: Colors.accent_bg_color

  readonly property font body: Qt.font({ family: "Adwaita Sans", pointSize: 11 })
  readonly property font heading: Qt.font({ family: "Adwaita Sans", pointSize: 11, weight: Font.Bold })
  readonly property font caption: Qt.font({ family: "Adwaita Sans", pointSize: 9 })
  readonly property font captionHeading: Qt.font({ family: "Adwaita Sans", pointSize: 9, weight: Font.Bold })
  readonly property font title1: Qt.font({ family: "Adwaita Sans", pointSize: 20, weight: Font.ExtraBold })
  readonly property font title2: Qt.font({ family: "Adwaita Sans", pointSize: 15, weight: Font.ExtraBold })
  readonly property font title3: Qt.font({ family: "Adwaita Sans", pointSize: 15, weight: Font.Bold })
  readonly property font title4: Qt.font({ family: "Adwaita Sans", pointSize: 13, weight: Font.Bold })
  readonly property font largeTitle: Qt.font({ family: "Adwaita Sans", pointSize: 24, weight: Font.Light })
  readonly property font monospace: Qt.font({ family: "Adwaita Mono", pointSize: 11 })
  readonly property font numeric: Qt.font({ family: "Adwaita Sans", pointSize: 11, features: { "tnum": 1 } })
  readonly property font numericHeading: Qt.font({ family: "Adwaita Sans", pointSize: 11, weight: Font.Bold, features: { "tnum": 1 } })

  readonly property int keycapRadius: 6
  // The user's exception: a workspace is a square, a little rounded, never Shell's pill.
  readonly property int workspaceRadius: 6
  readonly property int baseRadius: 8
  readonly property int menuItemRadius: 12
  readonly property int cardRadius: 12
  readonly property int tileRadius: 16
  readonly property int messageRadius: 16
  readonly property int popoverRadius: 20
  readonly property int toggleMenuRadius: 24
  readonly property int dateMenuRadius: 30
  readonly property int quickSettingsRadius: 36

  // Shell's 1 em: the 11 pt body in px.
  readonly property real em: body.pointSize * 96 / 72
  readonly property int basePadding: 6
  readonly property int baseMargin: 4
  readonly property int padding: 12
  readonly property int quickSettingsPadding: 18
  // A popover's distance from what it drops from and from the screen's edges (BoxPointer's -arrow-rise).
  readonly property int rise: 6

  readonly property int barHeight: 32
  readonly property int barItemHeight: 26
  readonly property int menuRowHeight: 36
  readonly property int buttonHeight: 34
  readonly property int iconButtonSize: 36
  readonly property int toggleHeight: 48
  readonly property int toggleWidth: 176

  readonly property int popupTime: 150
  readonly property int bannerTime: 200
  readonly property int quickTime: 100
  readonly property int panelButtonTime: 150
  readonly property int levelTime: 100
  readonly property int settle: 400

  // The exceptions' own (STYLE.md): the power menu's backdrop and clock, and the black the screens fade to before the lock.
  readonly property color backdrop: Qt.rgba(0, 0, 0, 0.88)
  readonly property font display: Qt.font({ family: "Adwaita Sans", pointSize: 64, weight: Font.Bold })
  readonly property color idle: Colors.dark_5

  // A label with its access key underlined, as the HIG marks one; the labels are the shell's own, so nothing needs escaping.
  function accessKey(label: string, key: string): string {
    const at = label.toUpperCase().indexOf(key.toUpperCase());
    return at < 0 ? label : `${label.slice(0, at)}<u>${label[at]}</u>${label.slice(at + 1)}`;
  }

  // A number and its unit kept together by a narrow no-break space, as the HIG writes them ("76 %", "1 Gb/s").
  function unit(value: var, unit: string): string {
    return `${value} ${unit}`;
  }

  // The foreground over whatever lies below, as libadwaita mixes currentColor.
  function overlay(alpha: real): color {
    return Qt.rgba(root.fg.r, root.fg.g, root.fg.b, alpha);
  }

  // St's st-lighten(): HSL lightness up by a fraction.
  function lighten(base: color, by: real): color {
    return Qt.hsla(base.hslHue, base.hslSaturation, Math.min(1, base.hslLightness + by), base.a);
  }
}
