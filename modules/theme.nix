{ lib, ... }:
let
  palettes = {
    dark = {
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
      overlay = "#d8dee9";
    };

    kanagawa = {
      fg = "#dcd7ba";
      muted = "#727169";
      blue = "#7e9cd8";
      red = "#e82424";
      sel = "#223249";
    };
  };

  # the structurally active palette
  colors = palettes.dark;

  # no '#' and lowercase, for rgb()/0x consumers
  rgb = lib.mapAttrs (_: v: lib.toLower (lib.removePrefix "#" v)) colors;

  # "rgba(r, g, b, alpha)" from a #RRGGBB color
  digitMap = lib.listToAttrs (
    lib.imap0 (i: c: lib.nameValuePair c i) (lib.stringToCharacters "0123456789abcdef")
  );
  hexToDec = hex: builtins.foldl' (acc: ch: acc * 16 + digitMap.${ch}) 0 (lib.stringToCharacters hex);
  rgba =
    color: alpha:
    let
      hex = lib.toLower (lib.removePrefix "#" color);
      r = hexToDec (lib.substring 0 2 hex);
      g = hexToDec (lib.substring 2 2 hex);
      b = hexToDec (lib.substring 4 2 hex);
    in
    "rgba(${toString r}, ${toString g}, ${toString b}, ${toString alpha})";

  # render order for rasi/CSS variable blocks
  vars = [
    "fg"
    "focusedBorderColor"
    "unfocusedBorderColor"
    "bg1"
    "bg2"
    "bg3"
    "bg4"
    "bg5"
    "black"
    "blackLight"
    "blue"
    "blueLight"
    "cyan"
    "cyanLight"
    "gray"
    "grayLight"
    "green"
    "greenLight"
    "magenta"
    "magentaLight"
    "primaryColor"
    "red"
    "redLight"
    "white"
    "whiteLight"
    "yellow"
    "yellowLight"
  ];
in
{
  modules.theme = {
    inherit
      palettes
      colors
      rgb
      rgba
      vars
      ;
  };
}
