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

The palette rule (`modules/theme/palette.nix`, `depth`): an opaque surface is
upstream's less 28 per channel (`#36363a` becomes `#1a1a1e`), for the whole
desktop (GTK, the terminal, hyprlock, hyprtoolkit and the shell alike); accents, text and translucent colours are
upstream's. libadwaita 1.10's dark surfaces equal 1.9's, so nothing outside the
shell changed. Shell mixes its states into opaque colours per surface; `Theme`
gives them as the foreground at the alpha that lands on the same colour over the
popover, so they hold over any surface.

| Theme | Value | Source | Role |
| --- | --- | --- | --- |
| `fg` | `#ffffff` | gs `$fg_color` | Text and symbols |
| `fgDim` | fg 55 % | gs `$card_insensitive_fg_color` (about 55 % over a card; 50 % over the popover would fall under 3:1 on cards), adw `--dim-opacity` | Secondary text: subtitles, ages, other months, the empty-state line |
| `fgFaint` | fg 16 % | ours | Empty workspaces |
| `fgStrong` | fg 80 % | ours | Text over album art, occupied workspaces |
| `placeholder` | fg 70 % | gs `%entry StLabel.hint-text` | A text field's placeholder |
| `panelBg` | `dark_5` `#000000` | gs `$panel_bg_color` | The bar |
| `popoverBg` | `shell_bg_color` `#1a1a1e` | gs `$bg_color` `#36363a` | Popovers, quick settings, the date menu, centred panels |
| `popoverBorder` | `shell_outer_borders_color` `#26262b` | gs `$outer_borders_color` (`lighten(bg, 5%)`) | A popover's 1 px edge |
| `cardBg` | `shell_card_bg_color` `#2b2b30` | gs `$card_bg_color` (`lighten(bg, 7%)`) | Quick toggle menus, inset cards (weather, events) |
| `messageBg` | `shell_message_bg_color` `#38383e` | gs `.message` `#54545a` | Notification cards and banners |
| `messageHoverBg` | message + 4 % lightness | gs `%card:hover` | A notification card under the pointer |
| `messageButtonBg`, `messageButtonHoverBg`, `messageButtonActiveBg` | fg 15 %, 30 %, 20 % | gs `%notification_button` | A notification's actions |
| `toastBg` | `#343437` | adw `$toast_bg_color` `#505053`, less 28 | The Undo toast |
| `osdBg` | `shell_osd_bg_color` `#121217` | gs `$osd_bg_color` (`lighten(#222226, 5%)`) | The OSD pill |
| `osdBorder` | fg 2 % | gs `$osd_outer_borders_color` | The OSD's edge |
| `tooltipBg`, `tooltipBorder` | black 90 %, fg 10 % | gs `%tooltip` | Tooltips |
| `separator` | fg 10 % | gs `.popup-separator-menu-item-separator` | Dividers |
| `shadowColor` | black 20 % | gs `$shadow_color` | Popover and banner shadows |
| `accentBg`, `accentFg` | `#3584e4`, `#ffffff` | adw `--accent-bg-color` | The one accent |
| `accentHover`, `accentActive` | accent + 4 %, + 9 % lightness | gs `%default_button` | An accent fill under the pointer, pressed |
| `destructiveHover`, `destructiveActive` | destructive + 4 %, + 9 % | as the accent's | A destructive button |
| `accentSegmentBg`, `accentSegmentHoverBg`, `segmentHoverBg` | accent mixed 15 % white (+ 4 %), fg 17 % | gs `.quick-toggle-menu-button` | A quick toggle's menu segment, on and off |
| `accentSeparator`, `segmentSeparator` | accent mixed 30 % white, fg 25 % | gs `.quick-toggle-separator` | The rule before it |
| `headerIconBg` | fg 20 % | gs `.quick-toggle-menu .header .icon` | A toggle menu's icon disc off |
| `checkBorder` | fg 15 % | gs `.check-box StIcon` | A check box off (the tray's menus) |
| `keycapBg`, `keycapShade` | fg 10 %, `card_shade_color` | adw `.keycap` | A key |
| `buttonBg` | fg 9 % | gs `%button` (`mix(fg, bg, 9%)`) | A button at rest |
| `buttonHoverBg` | fg 13 % | gs `%button:hover` (+4 %) | Under the pointer |
| `buttonActiveBg` | fg 19 % | gs `%button:active` (+9 %) | Pressed |
| `buttonCheckedBg`, `buttonCheckedHoverBg` | fg 18 %, 22 % | gs `%button:checked` (+8 %) | Held down while what it opens is open |
| `menuHoverBg`, `menuActiveBg` | fg 13 %, 16 % | gs `.popup-menu-item:hover`, `:active` | A row under the pointer or the keyboard, pressed |
| `selectedBg` | fg 15 % | the user's pick (Shell marks it as hover) | A row the keyboard is on |
| `panelHoverBg`, `panelActiveBg`, `panelActiveHoverBg` | fg 17 %, 28 %, 32 % | gs `panel_button()` | A bar item under the pointer, open, both |
| `switchBg`, `switchHoverBg` | fg 15 %, 20 % | gs `.toggle-switch` | A switch off |
| `switchKnob` | `#d7d7d8` | gs `.toggle-switch .handle` | Its knob off; white on |
| `troughBg` | fg 10 % | gs `.slider`, `.osd-window .level` | A slider's and a level's trough |
| `sliderKnob` | `#e8e8e8` | gs `.slider` `color` | A slider's knob; white under the pointer |
| `scrollHandle` | fg 28 % | gs `StScrollBar` `#727275`, `#9b9b9d` over bg | A scroll bar |
| `focusRing` | `accentBg` | ours, not gs `focus_ring()` | The keyboard's 2 px ring |
| `backdrop`, `idle` | black 88 %, `dark_5` | ours | The power menu's backdrop; what the screens fade to before the lock |

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
| `display` | 64 pt, 700 | ours | The power menu's clock only |

## Radii

| Theme | px | Source | Use |
| --- | --- | --- | --- |
| `keycapRadius` | 6 | adw `.keycap` | Keys |
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
| `settle` | 400 | `OutCubic` | ours | What is slow on purpose |

The OSD hides 1500 ms after its last change (gs `osdWindow.js` `HIDE_TIMEOUT`).

## Where 51 differed from the first board, settled at checkpoint 1

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

Taken from 51 as the user picked: the media card heads the center, Do Not
Disturb is a switch in the center's footer, one accent everywhere (the nixpkgs mode lost its blues), no
press bounce, and the dim behind centred panels is 0.6.

## Pieces

All in `common/`; `qst gallery` shows each in every state, and `design.sh`
holds it to the census. A piece's look comes from `hovered` and `pressed`
properties bound to its own mouse area, so the gallery can hold a state.

- `Button`: Shell's `%button`. 8 px, or `pill` (toggles' kin: Clear, Sign
  In). `flat` on a surface of its own (the media controls, an action that is
  secondary); `suggested` the one action a menu row asks for (Connect);
  `destructive` what cannot be taken back; `checked` while what it opens is
  open; `glyph` before the text, `expander` for an `ExpanderArrow` after it.
  Bold, 34 px. Disabled is the whole at 50 %, libadwaita's.
- `IconButton`: Shell's `.icon-button`, a circle round a 16 px symbol: 36 px,
  or `small` (28 px) beside a slider and in a row or a banner's header. It
  always has a `tooltip`; the lint fails one without.
- `BarButton` (`bar/`): Shell's `.panel-button`, a bold pill 26 px tall inside
  the bar's 32, filled only under the pointer or while open.
- `Switch`: Shell's `.toggle-switch`. In a row, the row takes the keyboard;
  alone, `focusable`.
- `Slider`: Shell's barLevel: 4 px trough, the accent up to 100 % and red past
  it after a 1 px gap, a 1 px mark at 100 % while below it, a 16 px knob. Its
  range reaches past 1 while the level does and holds still for a drag,
  which Escape puts back.
- `TextField`: Shell's `%entry` (8 px) for a password or a name; `search` for
  a search: a pill led by the search symbol. The launcher draws its own field
  in the same shape, led by the mode's symbol.
- `ListRow`: Shell's `.popup-menu-item`: 36 px, 12 px radius, its 16 px symbol
  in a column of its own. The keyboard's row takes `selectedBg`, never a ring.
- `ExpanderArrow`: MDI's `chevron-down`, turned by `pointing` and never by
  hand: down to up for what expands in place, right to down for what opens a
  menu under it.
- `Keycap`: libadwaita's `.keycap`.
- `Card`: what floats, and the only thing with a shadow: the popover surface,
  its 1 px edge and Shell's 0 2 4 shadow (`shadow.spreadBy: 2` for a banner,
  `shadow.visible: false` for the OSD, which Shell draws flat).
- `Toast`: libadwaita's toast, for what can be taken back (Clear's Undo).
- `EmptyLine`: what an empty list says, in the dim colour, where its first row
  would be. No status pages.
- `ScrollBar`, `FocusRing`, `Glyph`, `TooltipArea` (with the `tooltip/` layer):
  the scroll handle, the keyboard's 2 px ring, a `Symbols` path, a tooltip.

Not a piece: a press has no motion of its own; the pressed colour is the
feedback, as in GNOME.

## Surfaces

| Surface | Anatomy | Place | Size | Motion |
| --- | --- | --- | --- | --- |
| Bar | Workspaces led by the distro's logo (it does nothing), the clock, the tray left of the status button, then the status button | Top, edge to edge, black | 32 px; items 26 px pills | Fills over `panelButtonTime` |
| Popover off the bar (control centre, center) | A `Card` | `rise` below the bar, centred on its button, `rise` from the screen's edges | Control centre 400 px (two 176 px toggles, 18 px padding, radius 36); center radius 30; menus radius 20 with 6 px padding | Fade with a `rise` slide over `popupTime`, both ways |
| Tray menu | Shell's popup menu, cascading | Flush under the bar, from its icon's left edge | At least 15 em, radius 20, 6 px padding | Opens at once, goes as the pointer leaves |
| Toggle menu | Header (42 px disc round a 24 px icon, title-3), rows, a separator, settings rows | Under the toggle row that opens it, in the control centre | Radius 24 on `cardBg` | Height then fade |
| Centred panel (launcher, shortcuts, gallery) | A `Card` over a 0.6 dim | Centre of the focused screen | Widths in em | Opens in place |
| Banner (popup) | Header line (app icon and name, age, expand, close), the 48 px icon or picture, summary, body, actions | Top right, under the status area | 30 em, radius 16, `messageBg` | Fade and growth from 90 % (`OutBack`) over `bannerTime` |
| OSD | Symbol, a 160 px level (white, red past 100 %), the number; or a symbol and a word | Bottom centre, 4 em up | 56 px pill on `osdBg` | `quickTime` fade, gone 1.5 s after the last change |

## Type, symbols and motion

- Type: the classes above only, and text elides at a line limit. Bar items
  and buttons are `heading`; numbers that change are `numeric` or
  `numericHeading`.
- Symbols: every path is a `Symbols` property, which the build writes from
  Material Design Icons 7.4 (Pictogrammers, the set Nerd Fonts ships as nf-md;
  `scripts/symbols.tsv`, a line per symbol, a 24 px grid). Drawn at 16 px everywhere, 24 in a toggle menu's header,
  32 in the OSD and the launcher's rows, 64 on the power tiles. App icons are Papirus-Dark's; tray items draw what
  they send.
- Motion: the tokens above, each with its easing; keyboard selection never
  animates.

## Writing

GNOME's HIG: header capitals for titles, buttons, pills, menu items and our
notifications' summaries ("Collapse All", "In Use"); sentence case for
subtitles, states, placeholders and bind descriptions. "…" only where more
input follows, never on a settings item ("Network Settings"). An estimate says
about ("About 2 h 40 min left"). No text ends in a full stop. A narrow no-break
space (`Theme.unit`) before % and units ("76 %", "1 Gb/s"), none before
degrees ("5°"). A track's time is m:ss; a date is in the locale's order with
the day unpadded. An empty search says "No results". Access keys are
underlined in their labels (`Theme.accessKey`).

## Behaviour

- The pointer is a hand where a click does something, an arrow where it does
  nothing or only dismisses, a closed hand while dragging; a disabled area
  names both. Nothing shows only under the pointer.
- One click does one action, and a row's click does the obvious thing. A
  right click only ever opens a menu.
- Escape and a click away close every panel; Escape in a submenu goes back.
- The keyboard reaches every control: Tab and the arrows move, Return and
  Space act, a `FocusRing` shows where once keys have moved it.
- The wheel steps in notches (`WheelSteps`); only the center's list glides.
- Only the centred panels dim what is behind them.
- Every icon-only control has a tooltip, half a second after the pointer
  rests.
- A critical notification is marked one way: a 1 px red outline on its own
  card or box, never its group; a collapsed group leads with its critical
  lines, each after a red dot.

## Exceptions

- The bar is all black: Shell's panel, kept outside the overview.
- The power menu keeps its own backdrop, 28 px tiles and clock (`display`),
  and takes its keys without Alt, as nothing in it takes text.
- The workspaces are squares with a little rounding (`workspaceRadius`), not
  Shell's pills: the user's call.
- The forecast draws MET Norway's own colour icons, the service it comes from,
  not Adwaita's weather symbols.
- Caffeine is a quick toggle beside Night Light (GNOME has none), with a cup
  in the status button while it is on.
- The symbols are Material Design Icons, filled, not Adwaita's (an outlined
  bell, a sideways return): the user's call.
- The workspaces are numbered (hyprsplit's), an occupied one told from an
  empty one by colour alone, as a mark would crowd 26 px items.
- The focus ring is the accent, not Shell's lighter blue: one accent.
- The keyboard's row is `selectedBg` (15 %), apart from Shell's hover.
- A toggle menu's header icon is 24 px, Shell's, the one symbol between 16
  and 32.
- The media card's text sits over its album art, blurred, darkened and held
  to 3:1 by the census.
- The tray (GNOME has none) is on the bar itself: hidden until the pointer
  reaches the bar's right end, a strip up to 18 em that the wheel scrolls
  sideways, lingering 600 ms after the pointer leaves so a near miss still finds
  it, not a popover under the bar.
- The monitors mode's placeholder names what it lists ("Monitor layout…").
- hyprlock, hyprtoolkit and the idle fade follow their own configs.

## A new piece or surface

1. Draft it first: options shot in the test session for the user to pick.
2. Build it from the pieces above and Theme's tokens; a new value goes in
   Theme with its source here.
3. Give it a gallery entry if it is a piece, in every state.
4. `qst lint` clean: no literal colours, fonts, radii or durations, symbols
   from `Symbols` at their sizes, a shadow only on a `Card`, a tooltip on an
   `IconButton`.
5. Probe fields for what a test must see, and a scenario for its behaviour.
6. Chaos cases: floods, hostile names, hotplug under it, a 1024x600 screen,
   4K at scale 2.
