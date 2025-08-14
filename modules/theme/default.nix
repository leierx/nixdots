{ config, lib, ... }:
let
  cfg = config.dots.theme;
in
{
  options.dots.theme = {
    wallpaper = lib.mkOption { type = lib.types.path; default = ./assets/nixWallpaper.png; };
    nixLogoPng = lib.mkOption { type = lib.types.path; default = ./assets/nixLogo.png; };

    #-------------------------------------#

    # Primary/Selected Color
    primaryColor = lib.mkOption { type = lib.types.str; default = "#0E66D0"; };

    # Foreground
    fg = lib.mkOption { type = lib.types.str; default = "#f1f1f1"; };

    # Backgrounds
    bg1 = lib.mkOption { type = lib.types.str; default = "#1C1C1C"; };
    bg2 = lib.mkOption { type = lib.types.str; default = "#2F2F2F"; };
    bg3 = lib.mkOption { type = lib.types.str; default = "#3A3A3A"; };
    bg4 = lib.mkOption { type = lib.types.str; default = "#474747"; };
    bg5 = lib.mkOption { type = lib.types.str; default = "#515151"; };

    # Borders
    unfocusedBorderColor = lib.mkOption { type = lib.types.str; default = "#595959"; };
    focusedBorderColor = lib.mkOption { type = lib.types.str; default = cfg.primaryColor; };

    # Additional Colors with Light Variants
    black = lib.mkOption { type = lib.types.str; default = "#1e1e1e"; };
    blackLight = lib.mkOption { type = lib.types.str; default = "#323232"; };

    blue = lib.mkOption { type = lib.types.str; default = "#0E66D0"; };
    blueLight = lib.mkOption { type = lib.types.str; default = "#0875F6"; };

    cyan = lib.mkOption { type = lib.types.str; default = "#4BB0E3"; };
    cyanLight = lib.mkOption { type = lib.types.str; default = "#4FC0F7"; };

    green = lib.mkOption { type = lib.types.str; default = "#2BBF3E"; };
    greenLight = lib.mkOption { type = lib.types.str; default = "#2DD042"; };

    magenta = lib.mkOption { type = lib.types.str; default = "#9C48CC"; };
    magentaLight = lib.mkOption { type = lib.types.str; default = "#B24FEA"; };

    red = lib.mkOption { type = lib.types.str; default = "#F13A31"; };
    redLight = lib.mkOption { type = lib.types.str; default = "#FE3C33"; };

    white = lib.mkOption { type = lib.types.str; default = "#F1F1F1"; };
    whiteLight = lib.mkOption { type = lib.types.str; default = "#FEFEFE"; };

    gray = lib.mkOption { type = lib.types.str; default = "#818589"; };
    grayLight = lib.mkOption { type = lib.types.str; default = "#A3A6AA"; };

    yellow = lib.mkOption { type = lib.types.str; default = "#F1C50F"; };
    yellowLight = lib.mkOption { type = lib.types.str; default = "#FECF0F"; };
  };
}
