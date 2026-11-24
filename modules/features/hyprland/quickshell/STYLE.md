# The shell's style

GNOME 51 on the darker palette. Desktop surfaces (bar, popovers, quick
settings, banners, OSD, date menu) follow **gnome-shell 51**; app-like content
in a panel (rows, switches, entries) follows **libadwaita 1.10**. Values are
`Theme`'s; nothing else names a colour, font, radius, size or duration.
hyprlock, hyprtoolkit and the idle fade follow their own configs.

Every rule is tagged: `gs` (gnome-shell), `adw` (libadwaita), or **ours**
with why. **ours** is the user's call; never trade it back for GNOME's value.

Sources, from the 51 tarballs (`nix build --inputs-from .
nixpkgs-unstable#gnome-shell.src`, `#libadwaita.src`): `gs` is
`data/theme/gnome-shell-sass/` (checked against `gnome-shell-dark.css`) and
`js/ui/*.js` for motion; `adw` is `src/stylesheet/`. St's `st-mix()` is Sass
`mix()`, `st-lighten()` adds HSL lightness. 1 em = the 11 pt body = 14.67 px;
`to_em(px)` is px ÷ 16 × 1.091 em.

## Start here: a new piece

| You need | Use | Size, tokens |
| --- | --- | --- |
| Something that floats | `Card` | `popoverBg`, 1 px `popoverBorder`, the only shadow |
| A panel of its own | `Overlay` + `Card`, through `Panels` | width in em (Panel sizes), height to content, capped at the screen |
| A row in a list or menu | `ListRow` | 36 px, radius 12, 16 px symbol in its own column |
| An action | `Button` | 34 px, radius 8 or `pill`, bold |
| An action that is only a symbol | `IconButton` | 36 px circle (28 `small`, 24 `tiny`), 16 px symbol, always a `tooltip` |
| On or off | `Switch` | 46 × 26 |
| A level | `Slider` | 4 px trough, 16 px knob |
| Text in | `TextField` | 8 px, or `search`: a pill led by a symbol |
| A key | `Keycap` | 26 px, radius 6 |
| Nothing to show, a panel | `EmptyState` | dim 64 px symbol (or none) over title-3, centred |
| Nothing to show, a menu | `EmptyLine` | one dim line where the first row would be |
| A symbol | `Glyph` + `Symbols.<name>` | 16 px; 32 and 64 only where Symbols (below) says |
| A tooltip | `TooltipArea` in the owner | half a second after the pointer rests, at once from another (GTK's browse mode), fading in over `quickTime` |
| Anything else | a new token in `Theme`, a row here | |

Then:

1. Draft it on a design board first; the user picks.
2. Build from the pieces above; a new value is a `Theme` token with its row
   and tag here.
3. A gallery entry if it is a piece (`tests/GalleryWindow.qml`), every state.
4. `qst lint` clean (colours, fonts, radii, durations, symbol sizes, shadows,
   tooltips, cursors).
5. Probe fields for what a test must see; a scenario; chaos cases (floods,
   hostile names, hotplug under it, 1024x600, 4K at scale 2).

A piece's look comes from `hovered` and `pressed` bound to its own mouse area,
so the gallery can hold a state. Nothing that takes hover lies over that area:
Qt hovers one item and its ancestors only.

## Colours

The palette (`modules/theme/palette.nix`, `depth`): an opaque surface is
upstream's less 28 per channel (`#36363a` → `#1a1a1e`), the whole desktop
alike (**ours**: darker than GNOME). Accents, text, translucent colours are
upstream's. Shell mixes states into opaque colours per surface; `Theme` gives
them as the foreground at the alpha that lands on the same colour over the
popover, so they hold on any surface.

| Theme | Value | Source | Role |
| --- | --- | --- | --- |
| `fg` | `#ffffff` | gs `$fg_color` | Text, symbols |
| `fgDim` | fg 55 % | gs `$card_insensitive_fg_color` (50 % falls under 3:1 on cards), adw `--dim-opacity` | Subtitles, ages, other months, empty states |
| `fgFaint` | fg 16 % | ours | Empty workspaces |
| `fgStrong` | fg 80 % | ours | Text over album art, occupied workspaces |
| `placeholder` | fg 70 % | gs `%entry .hint-text` | A field's placeholder |
| `panelBg` | `#000000` | gs `$panel_bg_color` | The bar (**ours**: all black, Shell's outside the overview) |
| `popoverBg` | `#1a1a1e` | gs `$bg_color` | Popovers, quick settings, date menu, centred panels, popups |
| `popoverBorder` | `#26262b` | gs `$outer_borders_color` | A popover's 1 px edge |
| `cardBg` | `#2b2b30` | gs `$card_bg_color` | Toggle menus, inset cards (weather, events) |
| `messageBg`, `messageHoverBg` | `cardBg`, + 4 % lightness | **ours**: gs `.message` (card + 5 %) stood out against the darker desktop, and the popover's own colour vanished on the popover; gs `%card:hover` | The center's cards |
| `bannerBg`, `bannerHoverBg` | `popoverBg`, + 4 % lightness | **ours**: a popup is the popover, as every floating surface | Popups |
| `popupBorder` | fg 22 % | **ours**: a popup stands out from what is behind it | A banner's edge |
| `messageButtonBg`, `…HoverBg`, `…ActiveBg` | fg 15, 30, 20 % | gs `%notification_button` | A notification's actions |
| `osdBg`, `osdBorder` | `#121217`, fg 2 % | gs `$osd_bg_color`, `$osd_outer_borders_color` | The OSD |
| `tooltipBg`, `tooltipBorder` | black 90 %, fg 10 % | gs `%tooltip` | Tooltips |
| `separator` | fg 10 % | gs `.popup-separator-menu-item` | Dividers |
| `shadowColor` | black 20 % | gs `$shadow_color` | Card shadows |
| `accentBg`, `accentFg` | `#3584e4`, `#ffffff` | adw `--accent-bg-color` | The one accent (**ours**: no light blue anywhere) |
| `accentHover`, `accentActive` | + 4 %, + 9 % lightness | gs `%default_button` | Accent under the pointer, pressed |
| `destructiveBg`, `…Hover`, `…Active`, `destructive` | adw red, + 4 %, + 9 % | adw, as the accent's | What cannot be taken back; critical outlines |
| `accentSeparator`, `segmentSeparator` | accent mixed 30 % white, fg 25 % | gs `.quick-toggle-separator` | The rule before a toggle's menu segment |
| `headerIconBg` | fg 20 % | gs `.quick-toggle-menu .header .icon` | A toggle menu's disc off |
| `checkBorder` | fg 15 % | gs `.check-box` | A check box off (tray menus) |
| `keycapBg`, `keycapShade` | fg 10 %, `card_shade_color` | adw `.keycap` | A key |
| `buttonBg`, `buttonHoverBg`, `buttonActiveBg` | fg 9, 13, 19 % | gs `%button` (+4, +9 %) | A button at rest, hovered, pressed |
| `buttonCheckedBg`, `…HoverBg` | fg 18, 22 % | gs `%button:checked` | Held while what it opens is open |
| `menuHoverBg`, `menuActiveBg` | fg 13, 16 % | gs `.popup-menu-item` | A row hovered, pressed |
| `selectedBg` | fg 15 % | **ours**: Shell marks it as hover | The keyboard's row |
| `panelHoverBg`, `panelActiveBg`, `panelActiveHoverBg` | fg 17, 28, 32 % | gs `panel_button()` | A bar item hovered, open, both |
| `switchBg`, `switchHoverBg`, `switchKnob` | fg 15, 20 %, `#d7d7d8` | gs `.toggle-switch` | A switch off (white knob on) |
| `troughBg`, `sliderKnob` | fg 10 %, `#e8e8e8` | gs `.slider`, `.level` | Trough; knob (white hovered) |
| `scrollHandle` | fg 28 % | gs `StScrollBar` | A scroll bar |
| `focusRing` | `accentBg` | **ours**: one accent, not gs `focus_ring()`'s lighter blue | The keyboard's 2 px ring |
| `recording`, `bell`, `inUse`, `warning`, `success` | palette red, yellow, orange… | ours | Status glyphs |
| `backdrop`, `idle` | black 88 %, `#000000` | ours | Power menu backdrop; the idle fade |
| `skies` | gradients per sky | **ours**: colour on the weather card | Weather card: day, night, cloud, rain, snow, storm |
| `cover()` | the cover's main hue at OKLab 0.40, chroma at most 0.12; accent 0.84 (hover 0.80, pressed 0.76), none for a grey cover | **ours**: colour on the media card, white text past 7:1 on any hue | Media card; its seek bar and play button |

## Type

Adwaita Sans 11 pt; only these classes (gs `%title_1` … `%caption`, adw
`.title-1` … `.caption`). Text elides at a line limit.

| Theme | Size, weight | Use |
| --- | --- | --- |
| `title2` | 15 pt, 800 | The calendar's month, a monitor preview's title |
| `title3` | 15 pt, 700 | Empty states |
| `title4` | 13 pt, 700 | Toggle menu headers (**ours**: gs title-3, too heavy beside a 16 px symbol) |
| `largeTitle` | 24 pt, 300 | gs `%large_title` |
| `heading` | 11 pt, 700 | Row, card and toggle titles, buttons |
| `body` | 11 pt, 400 | Everything else |
| `captionHeading`, `caption` | 9 pt 700, 9 pt 400 | Badges; toggle subtitles, ages |
| `numeric`, `numericSemiBold`, `numericHeading` | 11 pt, tabular (400, 600, 700) | Numbers that change in place (gs `%numeric`); `numeric` for the bar's battery (**ours**: regular, gs `#panel` bold read heavy), `numericSemiBold` (**ours**: `Font.DemiBold`) for its clock and workspace numbers, `numericHeading` for OSD levels |
| `display` | 64 pt, 700 | **ours**: the power menu's clock only |

## Radii

| Theme | px | Source | Use |
| --- | --- | --- | --- |
| `keycapRadius` | 6 | adw `.keycap` | Keys |
| `workspaceRadius` | 6 | **ours**: squares, not Shell's pills | Workspaces |
| `baseRadius` | 8 | gs `$base_border_radius`, `%button` | Buttons that are not pills, notification actions (adw has 9) |
| `menuItemRadius` | 12 | gs `$menuitem_border_radius` | Every row in a popover or panel |
| `cardRadius` | 12 | gs `%card_common` | Inset cards |
| `tileRadius` | 16 | gs `%tile` | Launcher rows and tiles |
| `messageRadius` | 16 | gs `.message` | Notification cards and banners |
| `popoverRadius` | 20 | gs `.popup-menu-content` | Popover menus, the tray's |
| `toggleMenuRadius` | 24 | gs `.quick-toggle-menu` | A toggle's menu |
| `dateMenuRadius` | 30 | gs `.datemenu-popover` | The center |
| `quickSettingsRadius` | 36 | gs `.quick-settings` | The control centre |
| `height / 2` | pill | gs `$forced_circular_radius` | Toggles, icon buttons, search entry, bar items, OSD, tooltips |

## Sizes

| Theme | px | Source |
| --- | --- | --- |
| `em` | 14.67 | gs `stage` at 11 pt |
| `basePadding` | 6 | gs `$base_padding`: popover padding, spacing in a row |
| `baseMargin` | 4 | gs `$base_margin` |
| `padding` | 12 | gs `$base_padding × 2`: row sides, card padding |
| `quickSettingsPadding` | 18 | gs `.quick-settings` |
| `rise` | 6 | gs `-arrow-rise`: from the bar and the screen's edges |
| `barHeight`, `barItemHeight` | 32, 26 | gs `#panel` 2.2 em, `.panel-button` less its 3 px border |
| `menuRowHeight` | 36 | gs `%menuitem` |
| `buttonHeight` | 34 | adw button |
| `iconButtonSize` | 36 | gs `.quick-settings .icon-button` |
| `toggleHeight`, `toggleWidth` | 48, 12 em | gs `.quick-toggle` |

## Motion

| Theme | ms | Easing | Source | Use |
| --- | --- | --- | --- | --- |
| `popupTime` | 150 | `OutQuad` | gs `boxpointer.js` | A popover fades in sliding `rise` from what opened it, and back |
| `bannerTime` | 200 | `OutQuad` fade, `OutBack` scale 0.9 → 1 | gs `messageTray.js` | A banner showing, hiding |
| `quickTime` | 100 | `OutQuad` | gs `osdWindow.js`, `%menuitem`, `.toggle-switch` | OSD fade, a row's or switch's colour |
| `levelTime` | 100 | `OutQuad` | gs `osdWindow.js` | A level moving |
| `panelButtonTime` | 150 | | gs `panel_button()` | A bar item's fill |
| `settle` | 400 | `OutCubic` | ours | What is slow on purpose |

The OSD hides 1500 ms after its last change (gs `HIDE_TIMEOUT`). Keyboard
selection never animates. No press bounce (gs dropped it): the pressed colour
is the feedback. Every animation names its easing, the table's for its duration
(lint), and what appears eases in rather than pops: a disabled control's fade,
a field's, switch's or separator's colour, an empty state once the last row
has gone.

## Pieces

All in `common/`; `qst gallery` shows each in every state, `design.sh` holds it
to the census.

- `Button`: gs `%button`. 8 px or `pill` (Clear, Sign In); `flat` on a surface
  of its own (media controls, secondary actions); `suggested` the one action
  a row asks for; `destructive` what cannot be undone; `checked` while what it
  opens is open; `glyph` before the text, `expander` after. Bold, 34 px.
  Disabled: the whole at 50 % (adw).
- `IconButton`: gs `.icon-button`. 36 px circle, `small` 28 beside a slider or
  in a row, `tiny` 24 inline with a line of text, costing it no height (a
  notification's close and expander); the calendar's arrows are its day cells'
  size. Always a `tooltip` (lint fails one without).
- `BarButton` (`bar/`): gs `.panel-button`, regular-weight pill 26 px in the bar's 32,
  filled only hovered or open.
- `Switch`: gs `.toggle-switch`. In a row the row takes the keyboard; alone,
  `focusable`.
- `Slider`: gs barLevel. 4 px trough, accent to 100 %, red past it after a 1 px
  gap, a 1 px mark at 100 % while below, 16 px knob. Range reaches past 1 while
  the level does, holds still for a drag; Escape puts it back. A change from
  elsewhere (a key, another app) eases over `levelTime`, a drag follows the pointer.
- `TextField`: gs `%entry` (8 px) for a password or name; `search` a pill led
  by the search symbol. The launcher draws its own in that shape, led by the
  mode's symbol.
- `ListRow`: gs `.popup-menu-item`. 36 px, radius 12, 16 px symbol column. The
  keyboard's row is `selectedBg`, never a ring, and snaps; hover and a press
  ease over it (the launcher's and tray menu's rows alike).
- `ExpanderArrow`: MDI `chevron-down`, turned by `pointing`, never by hand:
  down→up expands in place, right→down opens a menu under it.
- `Keycap`: adw `.keycap`.
- `Card`: what floats, the only thing with a shadow: popover surface, 1 px edge,
  gs 0 2 4 shadow (`shadow.spreadBy: 2` for a banner, `shadow.visible: false`
  for the OSD, flat in gs).
- `EmptyState`: gs `.message-list-placeholder`, a dim symbol over title-3 in the
  middle of the room the list takes; the bell at 64 px (**ours**: gs 96). The
  center has the bell; the launcher no symbol (**ours**: its search already shows
  the mode's).
- `EmptyLine`: one dim line where the first row would be, for menus (**ours**
  over gs `.bt-menu-placeholder`: the toggle and header already show the
  symbol twice).
- `BatteryGlyph`: GNOME's battery, an upright cell filled to its charge: green,
  yellow at 25 % and below, red at 10 % and below, green with a bolt while charging.
- `ScrollBar`, `FocusRing`, `Glyph`, `TooltipArea` (with `tooltip/`): the
  scroll handle, the keyboard's 2 px ring, a `Symbols` path, a tooltip whose
  `HoverHandler` sits on its owner.

## Surfaces

| Surface | Anatomy | Place | Size | Motion |
| --- | --- | --- | --- | --- |
| Bar | Distro logo (os-release's, `Machine`) at 22 px in a workspace's 26 px square, 3 px further from them than they are from each other (does nothing; **ours**: set apart, it reads as the machine's, not a workspace), workspaces (**ours**: numbered squares, occupied by colour alone, a mark would crowd 26 px), clock, tray, status button (at least three symbols wide, an easy target; ours) | Top, edge to edge, black | 32 px; items 26 px pills, regular weight, SemiBold workspace numbers | Fills over `panelButtonTime`, a workspace's number with its square; status symbols are laid from the right edge, a new one fading in as the others slide aside, a leaving one fading before they close up, over `popupTime` |
| Tray (**ours**: GNOME has none) | Left of the status button, no fill (**ours**: one barely showed on the black bar), each icon hovered as a bar item: its first three icons in the order they came, then "+N" in the dim caption; under the pointer at the bar's right end, every icon, a strip the wheel scrolls sideways; lingers 600 ms; gone when empty | Bar | Three icons; at most 12 em expanded | Width eases over `popupTime`, growing leftwards |
| Tray menu | gs popup menu, cascading | At the pointer, a pixel off (**ours**: as trays have always opened them, not a dropdown under the bar) | At least 15 em, at most 34 em and the screen, the rest eliding and scrolling; radius 20, 6 px padding | Opens at once, goes as the pointer leaves; keys hold it, and it lets the keyboard go to a window clicked elsewhere |
| Popover off the bar (control centre, center) | A `Popover` + `Card` | `rise` below the bar, centred on its button, `rise` from screen edges | See Panel sizes | Fade + `rise` slide over `popupTime` |
| Quick toggle | Pill, symbol, title, subtitle; a menu segment after a 1 px rule in the pill's own colour, lighter only hovered (**ours**: gs lightens it always) | Control centre grid | 48 px × 12 em | |
| Toggle menu | Header (16 px symbol in a 32 px disc, title-4; **ours**: gs 24 in 42 and title-3 outweighed the rows in MDI's filled symbols), rows, separator, settings rows | Under the toggle row | Radius 24 on `cardBg` | The slot eases open, then the menu fades in; it fades out, then the slot eases shut; another menu of the same row fades out, the slot eases to its height and it fades in (ours: two slots of one row slid past each other). Rows come and go by their height, then fade, and keep the order they came in while it is open (ours: a row clicked never sorts away from the pointer) |
| Sound (**ours**) | The volume's slider alone on the card; its arrow opens Sound: "Output" and "Input" captions alike (no rule), each device with a symbol for what it is, Audio Settings (pwvucontrol); no microphone level or mute (seldom touched; pwvucontrol has them) | Under the levels | As a toggle menu | As a toggle menu |
| Control centre header | The battery's pill (gs); without one the machine, bare (**ours**): 24 px os-release logo, hostname bold, uptime dim; then screenshot, lock, power | Top of the control centre | 36 px | |
| Caffeine (**ours**: GNOME has none) | A toggle beside Night Light; a cup in the status button while on | Control centre | | |
| Centred panel (launcher, shortcuts, gallery) | A `Card` over a 0.6 dim (gs) | Centre of the focused screen | Widths in em | Opens in place |
| Banner (popup) | Never expands (**ours**: the center is where a long one is read); a click runs its default action, else its one button, else puts it away; held while the pointer is on it. Header line (app name, age, close; no app icon, **ours**: the body shows it, whole or as the picture's badge), 48 px icon or picture, summary, body, actions | Top right, under the status area | 34 em, radius 16, `bannerBg`, `popupBorder` edge | Fade and growth from 90 % over `bannerTime`, back the same way as it goes; a queued one arrives as it gets room |
| Center | Media card (gs place), groups per app on `messageBg`, each header age, expand, close (gs `MessageHeader`), a lone one folding without its text moving, calendar, weather; Do Not Disturb switch and Clear in the footer (gs); a click runs a lone card's default action, its arrow expands it; Clear slides every group off at once, no Undo (**ours**); groups hold their places while it is open | Under the clock that opened it, one per screen | See Panel sizes | The list eases its height, so the footer moves; a group's lines fade in as it unfolds and folds |
| Media card | The cover's colour (`cover`), white text; the art square, or as wide as 16:9 for a video's thumbnail; with two or three players a `tiny` button each at its corner, in the order they came, the one shown checked, the wheel stepping through them (**ours**: the user asked for colour) | Heads the center's list | | The colour settles over `settle`; a title or artist cut short slides to its end and back at 30 ms a pixel while the pointer is on the card, resting `settle` × 2 and × 3 (**ours**) |
| Weather card | MET Norway's own colour icons (**ours**: the service's, not Adwaita's), the sky as a gradient (`skies`) | Beside the calendar | | |
| OSD | Symbol, 160 px level (white, red past 100 %), number; or symbol and a word | Bottom centre, 4 em up | 56 px pill on `osdBg` | `quickTime` fade, gone 1.5 s after the last change |
| Power menu (**ours** throughout) | Own backdrop, `display` clock, five 148 px tiles radius 28 with 64 px symbols, each key a `Keycap` 12 px in from the top-right corner (GNOME's end-session dialog shows none), pressed without Alt | Full screen | | Fades in and out over `popupTime`, as a popover |

## Panel sizes

Widths in em of the body font, fixed per kind, so the shell's scale grows them
alike; heights the content's, capped at the screen less `rise` each side, the
rest scrolls. Narrower where the screen is, never wider.

| Panel | Width | Source |
| --- | --- | --- |
| Control centre | two 12 em toggles, 12 px gap, 18 px padding (27.3 em) | gs `.quick-toggle`, `.quick-settings` |
| Center | list 38 em, calendar beside it where 24 em is left | past a banner's width (**ours** over gs `.message-list` 29 em) |
| Banner | 34 em | gs `.notification-banner` |
| Launcher | 48 em, 68 with a preview | ours |
| Shortcuts | columns of 24 em | ours |
| Tray menu | at least 15 em, at most 34 em | gs `.popup-menu`; a banner's at most (ours) |
| Tray strip | at most 12 em | ours |

## Symbols

Material Design Icons 7.4, filled (**ours**: not Adwaita's outlined bell and
sideways return). Every path is a `Symbols` property, written by the build from
`scripts/symbols.tsv` (one line per symbol, 24 px grid). 16 px everywhere; 32
in the OSD and launcher rows; 64 on the power tiles and in an `EmptyState`.
App icons are Papirus-Dark's; tray items draw what they send.

## Writing

GNOME's HIG: header capitals for titles, buttons, pills, menu items, empty
states and our notifications' summaries ("Collapse All", "No Results");
sentence case for subtitles, states, placeholders, menu empty lines and bind
descriptions. "…" only where more input follows, or ends a state still under
way ("Connecting…", as GNOME's), never on a settings item;
the monitors mode's placeholder names what it lists ("Monitor layout…", ours).
An estimate says about ("About 2 h 40 min left"). No full stops. A narrow
no-break space (`Theme.unit`) before % and units ("76 %", "1 Gb/s"), none
before degrees ("5°"). Track time m:ss; dates in the locale's order, day
unpadded.

## Behaviour

- Pointer: a hand where a click acts, an arrow where it does nothing or only
  dismisses, a closed hand while dragging; a disabled area names both. Nothing
  shows only under the pointer.
- One click, one action; a row's click does the obvious thing. A right click
  opens a menu, or dismisses a notification, popup or center card (**ours**:
  the user's, over the HIG's menus only).
- Escape and a click away close every panel; Escape in a submenu goes back.
- The keyboard reaches every control in panels and menus: Tab and arrows move,
  Return and Space act, a `FocusRing` shows once keys have moved it (the bar has
  no keyboard focus; panels open from global shortcuts).
- The wheel steps a level or a row in notches (`WheelSteps`); a list scrolls as
  Qt's does, the center's easing each notch.
- Only centred panels dim what is behind them.
- Every icon-only control has a tooltip.
- A critical notification: a 1 px red edge on its own card or box, never its
  group's; a collapsed group leads with its critical lines, each after a red dot.
