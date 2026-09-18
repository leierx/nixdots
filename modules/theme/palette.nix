# Colour palettes, declared once at the top level and read by any module of
# any class. This is the dendritic answer to sharing values between files:
# no `specialArgs`, no imports between siblings.
{ lib, ... }:
{
  options.palettes = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
    default = { };
    description = "Named colour palettes, keyed by palette then by colour name";
  };

  config.palettes.ui = {
    fg = "#f1f1f1";
    focusedBorderColor = "#0E66D0";
    unfocusedBorderColor = "#595959";
    bg1 = "#1C1C1C";
    bg2 = "#2F2F2F";
    bg3 = "#3A3A3A";
    bg4 = "#474747";
    bg5 = "#515151";
    black = "#1e1e1e";
    blackLight = "#323232";
    blue = "#0E66D0";
    blueLight = "#0875F6";
    cyan = "#4BB0E3";
    cyanLight = "#4FC0F7";
    gray = "#818589";
    grayLight = "#A3A6AA";
    green = "#2BBF3E";
    greenLight = "#2DD042";
    magenta = "#9C48CC";
    magentaLight = "#B24FEA";
    primaryColor = "#0E66D0";
    red = "#F13A31";
    redLight = "#FE3C33";
    white = "#F1F1F1";
    whiteLight = "#FEFEFE";
    yellow = "#F1C50F";
    yellowLight = "#FECF0F";
  };

  config.palettes.adwaita_darker = {
    background = "#000000";
    foreground = "#deddda";
    cursor = "#deddda";
    cursor_text_color = "#000000";
    selection_background = "#1c1c1c";
    selection_foreground = "#c0bfbc";
    url_color = "#1a5fb4";
    active_border_color = "#1e1e1e";
    inactive_border_color = "#282828";
    bell_border_color = "#ed333b";
    active_tab_background = "#101010";
    active_tab_foreground = "#fcfcfc";
    inactive_tab_background = "#1c1c1c";
    inactive_tab_foreground = "#b0afac";
    color0 = "#000000";
    color1 = "#ed333b";
    color2 = "#57e389";
    color3 = "#ff7800";
    color4 = "#62a0ea";
    color5 = "#9141ac";
    color6 = "#5bc8af";
    color7 = "#deddda";
    color8 = "#9a9996";
    color9 = "#f66151";
    color10 = "#8ff0a4";
    color11 = "#ffa348";
    color12 = "#99c1f1";
    color13 = "#dc8add";
    color14 = "#93ddc2";
    color15 = "#f6f5f4";
  };

  # Matches the neovim colorscheme
  config.palettes.kanagawa = {
    fg = "#dcd7ba";
    muted = "#727169";
    blue = "#7e9cd8";
    red = "#e82424";
    sel = "#223249";
  };
}
