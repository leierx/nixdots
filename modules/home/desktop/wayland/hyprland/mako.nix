{
  flake.modules.homeManager.hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      colors = {
        bg1 = "#1C1C1C";
        bg3 = "#3A3A3A";
        fg = "#f1f1f1";
        primaryColor = "#0E66D0";
      };
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
          background-color = colors.bg1;
          text-color = colors.fg;
          width = 500;
          height = 150; # max popup height in px (shrinks to fit)
          outer-margin = 10; # margin outside the whole notification list
          margin = "10,0"; # margin around each individual notification
          padding = 20; # inner padding on each side
          border-size = 2;
          border-color = colors.primaryColor; # border color
          border-radius = 10;
          progress-color = "over ${colors.bg3}"; # progress indicator: "over" overlays, "source" replaces bg
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
