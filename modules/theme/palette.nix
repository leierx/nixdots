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

  # Matches the neovim colorscheme
  config.palettes.kanagawa = {
    fg = "#dcd7ba";
    muted = "#727169";
    blue = "#7e9cd8";
    red = "#e82424";
    sel = "#223249";
  };
}
