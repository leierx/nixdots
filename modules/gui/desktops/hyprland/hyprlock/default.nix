{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.dots.gui.hyprland.hyprlock.enable {
    security.pam.services.hyprlock = { };

    home-manager.sharedModules = [
      ({
        wayland.windowManager.hyprland.settings."$lockscreen" = "hyprlock";

        programs.hyprlock = {
          enable = true;
          settings = {
            background = {
              monitor = "";
              path = "${./background.jpg}";
            };

            general = {
              no_fade_in = true;
              no_fade_out = true;
              disable_loading_bar = true;
              hide_cursor = true;
            };

            label = [
              {
                monitor = "";
                text = "$TIME";
                color = "rgba(216, 222, 233, .75)";
                font_size = 50;
                font_family = "Hack";
                position = "0, 200";
                halign = "center";
                valign = "center";
              }
              {
                monitor = "";
                text = ''cmd[update:1000] echo -e "$(date +'%A, %B %d')"'';
                color = "rgba(216, 222, 233, .75)";
                font_size = 30;
                font_family = "Hack";
                position = "0, 100";
                halign = "center";
                valign = "center";
              }
            ];

            input-field = {
              monitor = "";
              size = "320, 55";
              dots_center = true;
              dots_size = 0.2;
              dots_spacing = 0.2;
              outer_color = "rgba(255, 255, 255, 0)";
              inner_color = "rgba(255, 255, 255, 0.1)";
              font_color = "rgb(200, 200, 200)";
              placeholder_text = "<i><span foreground=\"##ffffff99\">🔒  Enter Pass</span></i>";
              hide_input = false;
              position = "0, -100";
              halign = "center";
              valign = "center";
            };
          };
        };
      })
    ];
  };
}
