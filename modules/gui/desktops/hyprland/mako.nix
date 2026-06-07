{
  modules.homeManager.hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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
      # dependencies
      home.packages = [ pkgs.hack-font ];

      services.mako = {
        enable = true;
        settings = {
          # ── Binding options ─────────────────────────────────────────────
          on-button-left = "invoke-default-action";
          on-button-middle = "none";
          on-button-right = "dismiss";
          on-touch = "dismiss";
          # ── Style options ───────────────────────────────────────────────
          font = "Hack 12";
          background-color = bg1;
          text-color = fg;
          width = 500;
          height = 150; # max popup height in px (shrinks to fit)
          outer-margin = 10; # margin outside the whole notification list
          margin = "10,0"; # margin around each individual notification
          padding = 20; # inner padding on each side
          border-size = 2;
          border-color = primaryColor; # border color
          border-radius = 10;
          progress-color = "over ${bg3}"; # progress indicator: "over" overlays, "source" replaces bg
          icons = true;
          icon-path = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";
          history = true;
          format = ''<b>%s</b>\n%b''; # notification format string (grouped default: (%g) <b>%s</b>\n%b)
          default-timeout = 20000;
          ignore-timeout = true; # ignore app-sent expire timeout, use default-timeout
          max-visible = 8; # max visible notifications (-1 = unlimited)
        };
      };

      wayland.windowManager.hyprland.settings.on = [
        {
          _args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''function() hl.exec_cmd("${lib.getExe config.services.mako.package}") end'')
          ];
        }
      ];
    };
}
