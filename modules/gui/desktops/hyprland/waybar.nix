{
  modules.home.hyprland =
    {
      pkgs,
      lib,
      ...
    }:
    let
      colors = {
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
      programs.waybar = {
        enable = true;
        systemd.enable = false;
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
                  months = "<span color='${colors.blueLight}'><b>{}</b></span>";
                  days = "<span color='${colors.fg}'><b>{}</b></span>";
                  weeks = "<span color='${colors.cyanLight}'><b>{}</b></span>";
                  weekdays = "<span color='${colors.yellow}'><b>{}</b></span>";
                  today = "<span color='${colors.redLight}'><b><u>{}</u></b></span>";
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
        style =
          let
            defs = lib.concatMapStringsSep "\n" (
              name: "          @define-color ${name} ${colors.${name}};"
            ) vars;
          in
          ''
              ${defs}

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

      wayland.windowManager.hyprland = {
        settings = {
          on = [
            {
              _args = [
                "hyprland.start"
                (lib.generators.mkLuaInline ''function() hl.exec_cmd("${lib.getExe pkgs.waybar}") end'')
              ];
            }
            {
              _args = [
                "monitor.layout_changed"
                (lib.generators.mkLuaInline ''function() hl.exec_cmd("${pkgs.procps}/bin/pkill -SIGUSR2 waybar") end'')
              ];
            }
          ];
        };
      };
    };
}
