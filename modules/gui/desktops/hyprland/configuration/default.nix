{ config, pkgs, lib, flakeInputs, ... }:
let
  theme = config.dots.theme;
in
{
  config = lib.mkIf config.dots.gui.hyprland.enable {
    home-manager.sharedModules = [
      ({
        wayland.windowManager.hyprland = {
          enable = true;
          xwayland.enable = true;
          package = flakeInputs.hyprland.packages.${pkgs.system}.hyprland;
          plugins = [ flakeInputs.hyprsplit.packages.${pkgs.system}.hyprsplit ];

          settings = {
            "$mod" = "SUPER";

            env = [
              "QT_QPA_PLATFORMTHEME,qt6ct" # use newer qt6 for decorations
              "NIXOS_OZONE_WL,1" # for any ozone-based browser & electron apps to run on wayland
              "SDL_VIDEODRIVER,wayland"
              "GDK_BACKEND,wayland"
              "CLUTTER_BACKEND,wayland"
              "QT_QPA_PLATFORM,wayland"
              "ADW_DISABLE_PORTAL,1" # gtk4 please use config files
            ];

            exec-once = [ "$browser" ];
            exec = [
              "pidof ${pkgs.networkmanagerapplet}/bin/nm-applet || ${pkgs.networkmanagerapplet}/bin/nm-applet"
              "pidof ${pkgs.networkmanagerapplet}/libexec/hyprpolkitagent || ${pkgs.networkmanagerapplet}/libexec/hyprpolkitagent"
              "pidof ${flakeInputs.agsShell.packages.${pkgs.system}.default}/bin/ags-shell || ${flakeInputs.agsShell.packages.${pkgs.system}.default}/bin/ags-shell"
            ];

            plugin = {
              hyprsplit = {
                num_workspaces = 5;
                persistent_workspaces = true;
              };
            };

            general = {
              # borders
              border_size = 2;

              "col.inactive_border" = "rgb(${lib.removePrefix "#" theme.unfocusedBorderColor})";
              "col.active_border" = "rgb(${lib.removePrefix "#" theme.green}) rgb(${lib.removePrefix "#" theme.green}) rgb(${lib.removePrefix "#" theme.green}) rgb(${lib.removePrefix "#" theme.blue}) rgb(${lib.removePrefix "#" theme.blue}) rgb(${lib.removePrefix "#" theme.blue}) 30deg";

              # gaps
              gaps_in = 10;
              gaps_out = 20;

              # layout
              layout = "dwindle";
            };

            dwindle = {
              # spawn new windows to the right
              force_split = 2;
            };

            decoration = {
              # rounded corners
              rounding = 10;
              rounding_power = 2.0;

              # blur - default disabled
              blur.enabled = false;

              # window shadows
              shadow = {
                enabled = true;
                ignore_window = true;
                range = 40;
                render_power = 6;
                offset = "0 0";
                color = "rgba(0, 0, 0, 0.9)";
              };
            };

            animations = {
              enabled = false;
              first_launch_animation = true;
            };

            input = {
              kb_layout = config.services.xserver.xkb.layout;
              kb_variant = config.services.xserver.xkb.variant;
            };

            misc = {
              # font
              #font_family

              # disable default shit
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              force_default_wallpaper = 0;
              focus_on_activate = true;

              # clipboard
              middle_click_paste = false; # I dont use it
            };

            # mouse binds
            bindm = [
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
            ];

            # keyboard binds
            bind = [
              "$mod, Return, exec, $terminal"
              "$mod, D, exec, $applicationLauncher"
              "$mod, Q, exec, $screenshot"
              #"$mod, B, exec, ${config.systemModules.gui.rofi.plugins.rbw.exec}/bin/rofi-rbw"

              # Window managment
              "$mod, W, killactive"
              "$mod, S, togglefloating"
              "$mod, F, fullscreen"
              "$mod, M, fullscreen, 1"

              # moving about the WM
              "$mod, 1, split:workspace, 1"
              "$mod, 2, split:workspace, 2"
              "$mod, 3, split:workspace, 3"
              "$mod, 4, split:workspace, 4"
              "$mod, 5, split:workspace, 5"
              "$mod, 6, split:workspace, 6"

              "$mod SHIFT, 1, split:movetoworkspacesilent, 1"
              "$mod SHIFT, 2, split:movetoworkspacesilent, 2"
              "$mod SHIFT, 3, split:movetoworkspacesilent, 3"
              "$mod SHIFT, 4, split:movetoworkspacesilent, 4"
              "$mod SHIFT, 5, split:movetoworkspacesilent, 5"
              "$mod SHIFT, 6, split:movetoworkspacesilent, 6"

              "$mod, O, focusmonitor, +1"
              "$mod SHIFT, O, movewindow, mon:+1"

              "$mod, C, cyclenext"
              "$mod SHIFT, C, swapnext"

              "$mod, h, movefocus, l"
              "$mod, l, movefocus, r"
              "$mod, k, movefocus, u"
              "$mod, j, movefocus, d"

              "$mod SHIFT, h, movewindow, l"
              "$mod SHIFT, l, movewindow, r"
              "$mod SHIFT, k, movewindow, u"
              "$mod SHIFT, j, movewindow, d"
            ];

            # window rules
            windowrulev2 = [
              # floaters
              "float, class:^(gnome-calculator|org\.gnome\.Calculator)$"
              "float, initialClass:^(gcr-prompter|nm-openconnect-auth-dialog)$"

              # stay in focus
              "stayfocused, initialClass:^(gcr-prompter)$"
              "stayfocused, class:^(Rofi)$"

              # pinned
              "pin, initialClass:^(gcr-prompter|nm-openconnect-auth-dialog)$"

              # centered windows
              "center 1, initialClass:^(nm-openconnect-auth-dialog)$"

              # no decorations unless floating on single tile workspace
              "noborder, onworkspace:w[t1], floating:0"
              "rounding 0, onworkspace:w[t1], floating:0"
              "noshadow, onworkspace:w[t1], floating:0"

              # dont maximize on your own
              "suppressevent maximize, class:^(.*)$"

              # nm-auth-dialog size
              "size 640 510, initialClass:^(nm-openconnect-auth-dialog)$"

              # temporary floaties
              "tag +tempfloat, initialTitle:^(Open File)$"
              "tag +tempfloat, class:^(nm-connection-editor|pavucontrol)$"
              "float, tag:tempfloat"
              "size 45% 45%, tag:tempfloat"
            ];

            # workspace rules
            workspace = [
              "w[t1], gapsout:0"
            ];
          };

          # submaps
          extraConfig = ''
            # WM control center submap
            bind = $mod, X, exec, sleep 2 && hyprctl dispatch submap reset
            bind = $mod, X, submap, system_control
            submap = system_control

            # shut down computer
            bind = , ESCAPE, exec, systemctl poweroff
            bind = , ESCAPE, submap, reset

            # exit hyprland
            bind = , Q, exit
            bind = , Q, submap, reset

            # reload hyprland
            bind = , R, exec, hyprctl reload config-only
            bind = , R, submap, reset
            bind = $mod, R, exec, hyprctl reload
            bind = $mod, R, submap, reset

            # lockscreen
            bind = , L, exec, $lockscreen
            bind = , L, submap, reset

            bind = , catchall, submap, reset

            submap = reset
          '';
        };
      })
    ];
  };
}
