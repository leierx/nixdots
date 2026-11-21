# The shell's style

GNOME 51 on the darker palette: desktop surfaces (bar, popovers, quick
settings, banners, OSD, the date menu) follow **gnome-shell 51**; anything
app-like inside a panel (rows, switches, entries) follows **libadwaita 1.10**.
Only the exceptions at the end depart from it, each with its reason. Values are
`Theme`'s; nothing else in the QML names a colour, font, radius, size or
duration.

Sources, all from the 51 tarballs (`nix build --inputs-from .
nixpkgs-unstable#gnome-shell.src`, `#libadwaita.src`):

- `gs:` gnome-shell `data/theme/gnome-shell-sass/` (`_common.scss`,
  `_colors.scss`, `_drawing.scss`, `widgets/*.scss`), checked against the
  shipped `gnome-shell-dark.css`; `js/ui/*.js` for motion. St's `st-mix()` is
  Sass's `mix()`, `st-lighten()` adds HSL lightness (`src/st/st-theme-node.c`).
- `adw:` libadwaita `src/stylesheet/` (`_colors.scss`, `_common.scss`,
  `widgets/*.scss`).

Shell's 1 em is the 11 pt body, 14.67 px; `to_em(px)` is px ÷ 16 × 1.091 em,
so a Shell length in `to_em` is that many px at the default font.

## Colours

The palette rule: an opaque surface is upstream's less 14 per channel
(`#36363a` becomes `#28282c`); accents, text and translucent colours are
upstream's. libadwaita 1.10's dark surfaces equal 1.9's, so nothing outside the
shell changed. Shell mixes its states into opaque colours per surface; `Theme`
gives them as the foreground at the alpha that lands on the same colour over the
popover, so they hold over any surface.

| Theme | Value | Source | Role |
| --- | --- | --- | --- |
| `fg` | `#ffffff` | gs `$fg_color` | Text and symbols |
| `fgDim` | fg 50 % | gs `$insensitive_fg_color` (`mix(fg, bg, 50%)`), `.device-subtitle` | Secondary text: subtitles, ages, other months, the empty-state line |
| `fgFaint` | fg 16 % | ours | Empty workspaces |
| `fgStrong` | fg 80 % | ours | Text over album art, occupied workspaces |
| `panelBg` | `dark_5` `#000000` | gs `$panel_bg_color` | The bar |
| `popoverBg` | `shell_bg_color` `#28282c` | gs `$bg_color` `#36363a` | Popovers, quick settings, the date menu, centred panels |
| `popoverBorder` | `shell_outer_borders_color` `#343439` | gs `$outer_borders_color` (`lighten(bg, 5%)`) | A popover's 1 px edge |
| `cardBg` | `shell_card_bg_color` `#39393e` | gs `$card_bg_color` (`lighten(bg, 7%)`) | Quick toggle menus, inset cards (weather, events) |
| `messageBg` | `shell_message_bg_color` `#46464c` | gs `.message` `#54545a` | Notification cards and banners |
| `messageSecond`, `messageLower` | `#37373c`, `#2f2f34` | gs `.message:second-in-stack`, `:lower-in-stack` | The cards stacked under a collapsed group |
| `subMenuBg` | `shell_submenu_bg_color` `#48484e` | gs `$submenu_bg_color` (`lighten(bg, 13%)`) | A submenu opened in place |
| `osdBg` | `shell_osd_bg_color` `#202025` | gs `$osd_bg_color` (`lighten(#222226, 5%)`) | The OSD pill |
| `osdBorder` | fg 2 % | gs `$osd_outer_borders_color` | The OSD's edge |
| `tooltipBg`, `tooltipBorder` | black 90 %, fg 10 % | gs `%tooltip` | Tooltips |
| `separator` | fg 10 % | gs `.popup-separator-menu-item-separator` | Dividers |
| `shadowColor` | black 20 % | gs `$shadow_color` | Popover and banner shadows |
| `accentBg`, `accentFg` | `#3584e4`, `#ffffff` | adw `--accent-bg-color` | The one accent |
| `accentHover`, `accentActive` | accent + 4 %, + 9 % lightness | gs `%default_button` | An accent fill under the pointer, pressed |
| `buttonBg` | fg 9 % | gs `%button` (`mix(fg, bg, 9%)`) | A button at rest |
| `buttonHoverBg` | fg 13 % | gs `%button:hover` (+4 %) | Under the pointer |
| `buttonActiveBg` | fg 19 % | gs `%button:active` (+9 %) | Pressed |
| `buttonCheckedBg`, `buttonCheckedHoverBg` | fg 18 %, 22 % | gs `%button:checked` (+8 %) | Held down while what it opens is open |
| `buttonInsensitiveBg` | fg 5 % | gs `%button:insensitive` (−3 %) | Disabled |
| `menuHoverBg`, `menuActiveBg` | fg 13 %, 16 % | gs `.popup-menu-item:hover`, `:active` | A row under the pointer or the keyboard, pressed |
| `cardHoverBg` | fg 13 % | gs `%card:hover` | A clickable card under the pointer |
| `panelHoverBg`, `panelActiveBg`, `panelActiveHoverBg` | fg 17 %, 28 %, 32 % | gs `panel_button()` | A bar item under the pointer, open, both |
| `switchBg`, `switchHoverBg` | fg 15 %, 20 % | gs `.toggle-switch` | A switch off |
| `switchKnob` | `#d7d7d8` | gs `.toggle-switch .handle` | Its knob off; white on |
| `troughBg` | fg 10 % | gs `.slider`, `.osd-window .level` | A slider's and a level's trough |
| `sliderKnob` | `#e8e8e8` | gs `.slider` `color` | A slider's knob; white under the pointer |
| `scrollHandle`, `scrollHandleHover` | fg 28 %, 47 % | gs `StScrollBar` `#727275`, `#9b9b9d` over bg | A scroll bar |
| `focusRing` | `accentBg` | ours, not gs `focus_ring()` | The keyboard's 2 px ring |

## Type

Adwaita Sans at 11 pt, the type classes both name alike (gs `%title_1` …
`%caption`, adw `.title-1` … `.caption`), and nothing else.

| Theme | Size, weight | Use |
| --- | --- | --- |
| `title1` | 20 pt, 800 | |
| `title2` | 15 pt, 800 | |
| `title3` | 15 pt, 700 | |
| `title4` | 13 pt, 700 | |
| `largeTitle` | 24 pt, 300 | gs `%large_title` |
| `heading` | 11 pt, 700 | Row and card titles, toggle titles, buttons, the bar (gs `#panel` is bold) |
| `body` | 11 pt, 400 | Everything else |
| `captionHeading` | 9 pt, 700 | Badges |
| `caption` | 9 pt, 400 | Toggle subtitles, ages |
| `monospace` | Adwaita Mono 11 pt | Code only: attributes, versions, paths, clipboard text |
| `numeric`, `numericHeading` | 11 pt, tabular figures | Numbers that change in place (gs `%numeric`) |

## Radii

| Theme | px | Source | Use |
| --- | --- | --- | --- |
| `baseRadius` | 8 | gs `$base_border_radius`, `%button`, `%notification_button` | Buttons that are not pills, keycaps, notification actions |
| `menuItemRadius` | 12 | gs `$menuitem_border_radius` | Every row in a popover or panel |
| `cardRadius` | 12 | gs `%card_common` | Inset cards |
| `tileRadius` | 16 | gs `%tile` | Launcher rows and tiles (`.list-search-result`) |
| `messageRadius` | 16 | gs `.message` | Notification cards and banners |
| `popoverRadius` | 20 | gs `.popup-menu-content` (`$modal_radius × 1.25`) | Popover menus, the tray's |
| `toggleMenuRadius` | 24 | gs `.quick-toggle-menu` | A quick toggle's menu |
| `dateMenuRadius` | 30 | gs `.datemenu-popover` | The center |
| `quickSettingsRadius` | 36 | gs `.quick-settings` (`$modal_radius × 2.25`) | The control centre |
| `height / 2` | pill | gs `$forced_circular_radius` | Toggles, icon buttons, the search entry, bar items, the OSD, tooltips |

## Sizes and spacing

| Theme | px | Source |
| --- | --- | --- |
| `em` | 14.67 | gs `stage` at 11 pt |
| `basePadding` | 6 | gs `$base_padding`: a popover's padding, spacing in a row |
| `baseMargin` | 4 | gs `$base_margin` |
| `padding` | 12 | gs `$base_padding × 2`: a menu row's side padding, a card's |
| `quickSettingsPadding` | 18 | gs `.quick-settings` |
| `rise` | 6 | gs `.popup-menu-boxpointer -arrow-rise`: from the bar and the screen's edges |
| `barHeight` | 32 | gs `#panel` 2.2 em |
| `barItemHeight` | 26 | gs `.panel-button`: 32 less its 3 px transparent border |
| `symbolSize` | 16 | gs `$base_icon_size` |
| `menuRowHeight` | 36 | gs `%menuitem` (9 px above and below a line) |
| `buttonHeight` | 34 | adw button |
| `iconButtonSize` | 36 | gs `.quick-settings .icon-button` (10.5 px round a 16 px symbol) |
| `toggleHeight`, `toggleWidth` | 48, 176 | gs `.quick-toggle` (3.273 em, 12 em) |

## Motion

| Theme | ms | Easing | Source | Use |
| --- | --- | --- | --- | --- |
| `popupTime` | 150 | `OutQuad` | gs `boxpointer.js` `POPUP_ANIMATION_TIME` | A popover fades in sliding `rise` (6 px) from what opened it, and back the same way |
| `bannerTime` | 200 | `OutQuad` fade, `OutBack` scale 0.9 → 1 | gs `messageTray.js` `ANIMATION_TIME` | A banner showing and hiding |
| `quickTime` | 100 | `OutQuad` | gs `osdWindow.js` `FADE_TIME`, `%menuitem`, `.toggle-switch` | The OSD's fade, a row's or switch's colour |
| `levelTime` | 100 | `OutQuad` | gs `osdWindow.js` `LEVEL_ANIMATION_TIME` | A level moving |
| `panelButtonTime` | 150 | | gs `panel_button()` | A bar item's fill |
| `menuExpandTime` | 75 | | gs `quickSettings.js` (`POPUP_ANIMATION_TIME / 2`) | A toggle's menu grows, then its content fades in (and back) |
| `settle` | 400 | `OutCubic` | ours | What is slow on purpose |

The OSD hides 1500 ms after its last change (gs `osdWindow.js` `HIDE_TIMEOUT`).

## Where 51 differs from the board's mock-ups

- Buttons that are not pills are 8 px (gs `%button`), not pills; Shell keeps
  pills for toggles, icon buttons, the search entry and Clear.
- The slider's knob is 16 px and `#e8e8e8` (white under the pointer), not a
  20 px white one; its trough 4 px.
- A popover slides 6 px, in and out over 150 ms, rather than 10 px in and
  100 ms out.
- The OSD's level is white, not the accent; its trough 6 px.
- Shell's focus ring is its accent mixed 60 % with white; ours stays the accent.
- Radii: popovers 20, rows 12, banners 16, toggle menus 24, the date menu 30,
  quick settings 36.
