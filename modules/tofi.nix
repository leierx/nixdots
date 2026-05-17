{
  modules.homeManager.tofi =
    let
      fg = "#f1f1f1";
      focusedBorderColor = "#0E66D0";
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
      unfocusedBorderColor = "#595959";
      white = "#F1F1F1";
      whiteLight = "#FEFEFE";
      yellow = "#F1C50F";
      yellowLight = "#FECF0F";
    in
    {
      programs.tofi = {
        enable = true;
        settings = {
          hide-cursor = true;
          history = false;
          fuzzy-match = true; # This option is deprecated
          drun-launch = true;
          terminal = "wezterm";
          ascii-input = true; # This is faster, but means e.g. a search for "e" will not match "é".
          font = "Adwaita Sans";
          font-size = 24;
          background-color = bg1;
          outline-width = 0;
          border-width = 2;
          border-color = "#000000";
          text-color = fg;
          prompt-text = "";
          selection-color = primaryColor;
          width = 640;
          height = 480;
          corner-radius = 20;
          padding-top = 20;
          padding-bottom = 20;
          padding-left = 20;
          padding-right = 20;
        };
      };
    };
}
