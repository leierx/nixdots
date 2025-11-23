{ flakeInputs, pkgs, lib, config, nixosConfig, ... }:
{
  options.dots.homeManager.desktops.hyprland = {
    hypridle.enable = lib.mkOption { type = lib.types.bool; default = true; };
    hyprlock.enable = lib.mkOption { type = lib.types.bool; default = true; };
    hyprpaper.enable = lib.mkOption { type = lib.types.bool; default = true; };
  };

  imports = [
    ./hypridle.nix
    ./hyprlock
    ./hyprpaper
    ../../apps/wezterm.nix
    ../../apps/fuzzel.nix
  ];

  config = {
    # Must have's
    home.packages = [
      pkgs.wl-clipboard # wayland clipboard utility
      flakeInputs.ags.packages.${pkgs.system}.agsFull
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      package = nixosConfig.programs.hyprland.package;
      plugins = [ flakeInputs.hyprsplit.packages.${pkgs.system}.hyprsplit ];
      settings = {
        "$mod" = "SUPER";
        "$terminal" = "wezterm";
        "$applicationLauncher" = "fuzzel";
        "$screenshot" = "${pkgs.hyprshot}/bin/hyprshot --mode region --freeze --silent --clipboard-only";

        env = [
          "QT_QPA_PLATFORMTHEME,qt6ct" # use newer qt6 for decorations
          "NIXOS_OZONE_WL,1" # for any ozone-based browser & electron apps to run on wayland
          "SDL_VIDEODRIVER,wayland" # SDL_VIDEODRIVER = wayland
          "GDK_BACKEND,wayland" # Forces GTK3 ⇒ Wayland
          "QT_QPA_PLATFORM,wayland" # Forces Qt to Wayland
          "ADW_DISABLE_PORTAL,1" # gtk4 please use config files
        ];

        exec = [
          "pidof ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent || ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
          "pidof ${flakeInputs.agsShell.packages.${pkgs.system}.default}/bin/ags-shell || ${flakeInputs.agsShell.packages.${pkgs.system}.default}/bin/ags-shell"
        ] ++ lib.optionals nixosConfig.networking.networkmanager.enable [
            "pidof ${pkgs.networkmanagerapplet}/bin/nm-applet || ${pkgs.networkmanagerapplet}/bin/nm-applet"
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
          "col.inactive_border" = "rgb(595959)";
          "col.active_border" = "rgb(2bbf3e) rgb(2bbf3e) rgb(2bbf3e) rgb(0e66d0) rgb(0e66d0) rgb(0e66d0) 30deg"; # blue blue blue, green green green
          # gaps
          gaps_in = 10;
          gaps_out = 20;
          # layout
          layout = "dwindle";
        };

        dwindle.force_split = 2; # spawn new windows to the right

        decoration = {
          # rounded corners
          rounding = 10;
          rounding_power = 2.0;
          # blur
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

        animations.enabled = false; # disable animations

        input = {
          kb_layout = nixosConfig.services.xserver.xkb.layout;
          kb_variant = nixosConfig.services.xserver.xkb.variant;
        };

        misc = {
          # disable default shit
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          force_default_wallpaper = 0;
          focus_on_activate = true;
          # clipboard
          middle_click_paste = false; # I dont use it
        };

        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
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
          # window managment
          "$mod, w, killactive"
          "$mod, s, togglefloating"
          "$mod, f, fullscreen"
          "$mod, m, fullscreen, 1"
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
          "float, initialClass:^(nm-openconnect-auth-dialog)$"
          # pinned
          "pin, initialClass:^(nm-openconnect-auth-dialog)$"
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
          # single tiled, disable outside gaps
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
  };
}
