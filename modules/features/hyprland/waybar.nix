root: {
  flake.modules.homeManager.hyprland =
    { lib, pkgs, ... }:
    let
      colors = root.config.palettes.ui;
      inherit (root.config.hyprland) workspaces;

    in
    {
      # the bar's font-family
      home.packages = [ pkgs.adwaita-fonts ];

      programs.waybar = {
        enable = true;
        systemd.enable = true;
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
              # hyprsplit numbers monitor k's workspaces k*n+1..(k+1)*n; show them as 1..n
              format-icons = lib.genAttrs (map toString (lib.range 1 (4 * workspaces))) (
                id: toString (lib.mod (lib.toInt id - 1) workspaces + 1)
              );
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
            defs = lib.concatMapStringsSep "\n" (name: "          @define-color ${name} ${colors.${name}};") (
              lib.attrNames colors
            );
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

      wayland.windowManager.hyprland.settings.on = [
        {
          _args = [
            "monitor.layout_changed"
            (lib.generators.mkLuaInline ''function() hl.exec_cmd("systemctl --user reload waybar") end'')
          ];
        }
      ];
    };
}
