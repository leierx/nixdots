{
  flake.modules.homeManager.hyprland =
    { pkgs, lib, ... }:
    {
      programs.waybar = {
        enable = true;
        systemd.enable = false;
        settings = {
          topbar = {
            layer = "top";
            position = "top";
            height = 30;

            modules-left = [
              "custom/os-logo"
              "hyprland/workspaces"
            ];

            modules-center = [
              "clock"
            ];

            modules-right = [
              "battery"
              "tray"
            ];

            "custom/os-logo" = {
              format = "";
              tooltip = false;
            };

            "hyprland/workspaces" = {
              format = "{icon}";
              all-outputs = false;
              format-icons = {
                "1" = "1";
                "2" = "2";
                "3" = "3";
                "4" = "4";
                "5" = "5";
                "6" = "1";
                "7" = "2";
                "8" = "3";
                "9" = "4";
                "10" = "5";
                "11" = "1";
                "12" = "2";
                "13" = "3";
                "14" = "4";
                "15" = "5";
                "16" = "1";
                "17" = "2";
                "18" = "3";
                "19" = "4";
                "20" = "5";
              };
            };

            clock = {
              format = "{:%a %d %B - %H:%M}";
              tooltip-format = "<tt><small>{calendar}</small></tt>";
              calendar = {
                mode = "month";
                on-scroll = 1;
                format = {
                  months = "<span color='#ffead3'><b>{}</b></span>";
                  days = "<span color='#ecc6d9'><b>{}</b></span>";
                  weekdays = "<span color='#ffcc66'><b>{}</b></span>";
                  today = "<span color='#ff6699'><b><u>{}</u></b></span>";
                };
              };
            };

            battery = {
              states = {
                warning = 30;
                critical = 15;
              };
              format = "{capacity}% {icon}";
              format-charging = "{capacity}% ";
              format-plugged = "{capacity}% ";
            };

            tray = {
              icon-size = 16;
              spacing = 10;
            };
          };
        };
        style = ''
          #custom-os-logo {
            /* Size relative to font — change this one value to scale on any monitor */
            min-width:  2em;
            min-height: 2em;

            background-image:    url("/home/leier/.config/waybar/nixos.svg");
            background-repeat:   no-repeat;
            background-position: center;
            background-size:     contain;

            /* Remove default label padding so the image fills the space cleanly */
            padding: 0 0.4em;
          }
        '';
      };

      # autostart
      wayland.windowManager.hyprland.settings.exec-once = [ "${lib.getExe pkgs.waybar}" ];
    };
}
