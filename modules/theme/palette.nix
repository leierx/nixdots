{ lib, ... }:
let
  # How far below GNOME's own dark surfaces: GNOME's look, darker, its steps between surfaces kept
  depth = 28;
  channel =
    by: hex:
    lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString (lib.max 0 (lib.fromHexString hex - by))));
  less =
    by: hex:
    "#"
    + lib.concatMapStrings (i: channel by (lib.substring i 2 hex)) [
      1
      3
      5
    ];
  darker = less depth;
  # Black from edge to edge was too much for a terminal
  terminal = less (depth / 2);
in
{
  options.palettes = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
    default = { };
    description = "Named colour palettes, keyed by palette then by colour name";
  };

  # libadwaita 1.10's dark style under its own names (doc/css-variables.md), GNOME Shell 51's
  # surfaces under its Sass names with a shell_ prefix, and ghostty's "Adwaita Dark" terminal colours;
  # translucent ones are CSS #rrggbbaa.
  # The opaque surfaces and the terminal background are upstream's, written as upstream has them, made `darker` (the terminal half as much)
  config.palettes.adwaita_darker = {
    accent_bg_color = "#3584e4";
    accent_fg_color = "#ffffff";
    accent_color = "#81d0ff";
    destructive_bg_color = "#c01c28";
    destructive_fg_color = "#ffffff";
    destructive_color = "#ff938c";
    success_bg_color = "#26a269";
    success_fg_color = "#ffffff";
    success_color = "#78e9ab";
    warning_bg_color = "#cd9309";
    warning_fg_color = "#000000cc";
    warning_color = "#ffc252";
    error_bg_color = "#c01c28";
    error_fg_color = "#ffffff";
    error_color = "#ff938c";

    window_bg_color = darker "#222226";
    window_fg_color = "#ffffff";
    view_bg_color = darker "#1d1d20";
    view_fg_color = "#ffffff";
    headerbar_bg_color = darker "#2e2e32";
    headerbar_fg_color = "#ffffff";
    headerbar_border_color = "#ffffff";
    headerbar_backdrop_color = darker "#222226";
    headerbar_shade_color = "#0000065c";
    headerbar_darker_shade_color = "#00000ce6";
    sidebar_bg_color = darker "#2e2e32";
    sidebar_fg_color = "#ffffff";
    sidebar_backdrop_color = darker "#28282c";
    sidebar_border_color = "#0000065c";
    sidebar_shade_color = "#00000640";
    secondary_sidebar_bg_color = darker "#28282c";
    secondary_sidebar_fg_color = "#ffffff";
    secondary_sidebar_backdrop_color = darker "#252529";
    secondary_sidebar_border_color = "#0000065c";
    secondary_sidebar_shade_color = "#00000640";
    card_bg_color = "#ffffff14";
    card_fg_color = "#ffffff";
    card_shade_color = "#0000065c";
    overview_bg_color = darker "#28282c";
    overview_fg_color = "#ffffff";
    thumbnail_bg_color = darker "#39393d";
    thumbnail_fg_color = "#ffffff";
    active_toggle_bg_color = "#ffffff33";
    active_toggle_fg_color = "#ffffff";
    dialog_bg_color = darker "#36363a";
    dialog_fg_color = "#ffffff";
    popover_bg_color = darker "#36363a";
    popover_fg_color = "#ffffff";
    popover_shade_color = "#00000640";
    shade_color = "#00000640";
    scrollbar_outline_color = "#00000cf2";

    shell_bg_color = darker "#36363a";
    shell_base_color = darker "#222226";
    shell_osd_bg_color = darker "#2e2e33";
    shell_outer_borders_color = darker "#424247";
    shell_card_bg_color = darker "#47474c";
    shell_message_bg_color = darker "#54545a";

    accent_blue = "#3584e4";
    accent_teal = "#2190a4";
    accent_green = "#3a944a";
    accent_yellow = "#c88800";
    accent_orange = "#ed5b00";
    accent_red = "#e62d42";
    accent_pink = "#d56199";
    accent_purple = "#9141ac";
    accent_slate = "#6f8396";

    blue_1 = "#99c1f1";
    blue_2 = "#62a0ea";
    blue_3 = "#3584e4";
    blue_4 = "#1c71d8";
    blue_5 = "#1a5fb4";
    green_1 = "#8ff0a4";
    green_2 = "#57e389";
    green_3 = "#33d17a";
    green_4 = "#2ec27e";
    green_5 = "#26a269";
    yellow_1 = "#f9f06b";
    yellow_2 = "#f8e45c";
    yellow_3 = "#f6d32d";
    yellow_4 = "#f5c211";
    yellow_5 = "#e5a50a";
    orange_1 = "#ffbe6f";
    orange_2 = "#ffa348";
    orange_3 = "#ff7800";
    orange_4 = "#e66100";
    orange_5 = "#c64600";
    red_1 = "#f66151";
    red_2 = "#ed333b";
    red_3 = "#e01b24";
    red_4 = "#c01c28";
    red_5 = "#a51d2d";
    purple_1 = "#dc8add";
    purple_2 = "#c061cb";
    purple_3 = "#9141ac";
    purple_4 = "#813d9c";
    purple_5 = "#613583";
    brown_1 = "#cdab8f";
    brown_2 = "#b5835a";
    brown_3 = "#986a44";
    brown_4 = "#865e3c";
    brown_5 = "#63452c";
    light_1 = "#ffffff";
    light_2 = "#f6f5f4";
    light_3 = "#deddda";
    light_4 = "#c0bfbc";
    light_5 = "#9a9996";
    dark_1 = "#77767b";
    dark_2 = "#5e5c64";
    dark_3 = "#3d3846";
    dark_4 = "#241f31";
    dark_5 = "#000000";

    background = terminal "#1d1d20";
    foreground = "#ffffff";
    cursor = "#ffffff";
    cursor_text_color = terminal "#1d1d20";
    selection_background = "#ffffff";
    selection_foreground = "#5e5c64";
    color0 = "#241f31";
    color1 = "#c01c28";
    color2 = "#2ec27e";
    color3 = "#f5c211";
    color4 = "#1e78e4";
    color5 = "#9841bb";
    color6 = "#0ab9dc";
    color7 = "#c0bfbc";
    color8 = "#5e5c64";
    color9 = "#ed333b";
    color10 = "#57e389";
    color11 = "#f8e45c";
    color12 = "#51a1ff";
    color13 = "#c061cb";
    color14 = "#4fd2fd";
    color15 = "#f6f5f4";
  };
}
