{
  modules.homeManager.hyprland =
    { pkgs, lib, ... }:
    {
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        systemd.targets = [ "hyprland-session.target" ];
        settings = {
          topbar = {
            name = "topbar";
            height = 42;
            spacing = 0;

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
              format = " ";
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
              format = "{:%a %d %B ‧ %H:%M}";
              tooltip-format = "<tt><small>{calendar}</small></tt>";
              calendar = {
                mode = "year";
                mode-mon-col = 4;
                weeks-pos = "right";
                format = {
                  months = "<span color='#0875F6'><b>{}</b></span>";
                  days = "<span color='#f1f1f1'><b>{}</b></span>";
                  weeks = "<span color='#4FC0F7'><b>{}</b></span>";
                  weekdays = "<span color='#F1C50F'><b>{}</b></span>";
                  today = "<span color='#FE3C33'><b><u>{}</u></b></span>";
                };
              };
            };

            battery = {
              full-at = 95;
              states = {
                warning = 25;
                critical = 10;
              };
              format = "{capacity}%";
            };

            tray = {
              icon-size = 20;
            };
          };
        };
        style = ''
          @define-color fg #f1f1f1;
          @define-color focusedBorderColor #0E66D0;
          @define-color bg1 #1C1C1C;
          @define-color bg2 #2F2F2F;
          @define-color bg3 #3A3A3A;
          @define-color bg4 #474747;
          @define-color bg5 #515151;
          @define-color black #1e1e1e;
          @define-color blackLight #323232;
          @define-color blue #0E66D0;
          @define-color blueLight #0875F6;
          @define-color cyan #4BB0E3;
          @define-color cyanLight #4FC0F7;
          @define-color gray #818589;
          @define-color grayLight #A3A6AA;
          @define-color green #2BBF3E;
          @define-color greenLight #2DD042;
          @define-color magenta #9C48CC;
          @define-color magentaLight #B24FEA;
          @define-color primaryColor #0E66D0;
          @define-color red #F13A31;
          @define-color redLight #FE3C33;
          @define-color unfocusedBorderColor #595959;
          @define-color white #F1F1F1;
          @define-color whiteLight #FEFEFE;
          @define-color yellow #F1C50F;
          @define-color yellowLight #FECF0F;

          * {
            font-family: 'Adwaita Sans';
            font-size: 12pt;
            color: @fg;
          }

          window#waybar.topbar {
              all: unset;
              background: #000;
          }

          window#waybar.topbar > box { margin: 4pt 2pt; }

          #custom-os-logo * { all: unset; }
          #custom-os-logo {
            background-image: url('${./assets/nixos.svg}');
            background-position: center;
            background-repeat: no-repeat;
            background-size: contain;
            min-width: 20pt;
            margin: 0 4pt;
          }

          #workspaces * { all: unset; }
          #workspaces {
            font-weight: bold;
            color: @fg;
          }

          #workspaces button {
            border-radius: 3pt;
            min-width: 24pt;
          }

          #workspaces button.empty label { color: rgba(241, 241, 241, 0.4); }
          #workspaces button.active { background-color: rgba(255, 255, 255, 0.25); }
          #workspaces button:hover { background-color: rgba(255, 255, 255, 0.15); }
          #workspaces button:hover:active { background-color: rgba(255, 255, 255, 0.25); }

          #clock { font-weight: 500; }

          #battery { font-weight: 500; color: @fg; padding: 0 10px; }
          #battery.warning { color: @yellow; }
          #battery.critical { color: @red; animation: pulse 1s ease-in-out infinite alternate; }
          #battery.charging, #battery.plugged { animation: charging 1.5s ease-in-out infinite alternate; }
          @keyframes charging { 0% { color: @blue; opacity: 0.8; } 100% { color: @blueLight; opacity: 1; } }
          @keyframes pulse { from { color: @red; } to { opacity: 0.4; } }

          #tray { padding: 0 6pt; }
          #tray widget>image { margin: 0 2pt; }
          #tray > .passive { -gtk-icon-effect: dim; }
          #tray > .needs-attention { -gtk-icon-effect: highlight; }
        '';
      };

      wayland.windowManager.hyprland.settings.on = [
        {
          _args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''function() hl.exec_cmd("${lib.getExe pkgs.waybar}") end'')
          ];
        }
      ];
    };
}
