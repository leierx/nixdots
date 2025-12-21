{
  lib,
  config,
  pkgs,
  flakeInputs,
  ...
}:
let
  cfg = config.nixdots.graphical.desktops.hyprland;
in
{
  options.nixdots.graphical.desktops.hyprland = {
    enable = lib.mkEnableOption "Enable Hyprland desktop (NixOS + Home Manager)";

    hypridle.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable hypridle";
    };

    hyprlock.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable hyprlock";
    };

    hyprpaper.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable hyprpaper";
    };
  };

  imports = [
    ./hypridle.nix
    ./hyprlock
    ./hyprpaper
  ];

  config = lib.mkIf cfg.enable {
    nixdots.programs.wezterm.enable = true; # terminal of choice
    nixdots.programs.fuzzel.enable = true; # app launcher of choice

    # file-manager
    services.gvfs.enable = true;
    services.gnome.sushi.enable = true;
    environment.systemPackages = [ pkgs.nautilus ];

    # Hyprland install (from flake)
    programs.hyprland = {
      enable = true;
      package = flakeInputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = flakeInputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    # cachix to speed up build times
    nix.settings = {
      substituters = lib.mkAfter [ "https://hyprland.cachix.org" ];
      trusted-substituters = lib.mkAfter [ "https://hyprland.cachix.org" ];
      trusted-public-keys = lib.mkAfter [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

    # Hyprland config
    home-manager.users.${config.nixdots.core.primaryUser.username} = {
      home.packages = [
        pkgs.wl-clipboard
        flakeInputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.agsFull
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = true;

        package = config.programs.hyprland.package;

        plugins = [ flakeInputs.hyprsplit.packages.${pkgs.stdenv.hostPlatform.system}.hyprsplit ];

        settings = {
          "$mod" = "SUPER";
          "$terminal" = "wezterm";
          "$applicationLauncher" = "fuzzel";
          "$screenshot" = "${pkgs.hyprshot}/bin/hyprshot --mode region --freeze --silent --clipboard-only";

          env = [
            "QT_QPA_PLATFORMTHEME,qt6ct"
            "NIXOS_OZONE_WL,1"
            "SDL_VIDEODRIVER,wayland"
            "GDK_BACKEND,wayland"
            "QT_QPA_PLATFORM,wayland"
            "ADW_DISABLE_PORTAL,1"
          ];

          exec = [
            "pidof ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent || ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
            "pidof ${flakeInputs.agsShell.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/ags-shell || ${flakeInputs.agsShell.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/ags-shell"
          ]
          ++ lib.optionals config.networking.networkmanager.enable [
            "pidof ${pkgs.networkmanagerapplet}/bin/nm-applet || ${pkgs.networkmanagerapplet}/bin/nm-applet"
          ];

          plugin.hyprsplit = {
            num_workspaces = 5;
            persistent_workspaces = true;
          };

          general = {
            border_size = 2;
            "col.inactive_border" = "rgb(595959)";
            "col.active_border" = "rgb(2bbf3e) rgb(2bbf3e) rgb(2bbf3e) rgb(0e66d0) rgb(0e66d0) rgb(0e66d0) 30deg";
            gaps_in = 10;
            gaps_out = 20;
            layout = "dwindle";
          };

          dwindle.force_split = 2;

          decoration = {
            rounding = 10;
            rounding_power = 2.0;

            blur.enabled = false;

            shadow = {
              enabled = true;
              ignore_window = true;
              range = 40;
              render_power = 6;
              offset = "0 0";
              color = "rgba(0, 0, 0, 0.9)";
            };
          };

          animations.enabled = false;

          input = {
            kb_layout = config.services.xserver.xkb.layout;
            kb_variant = config.services.xserver.xkb.variant;
          };

          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            force_default_wallpaper = 0;
            focus_on_activate = true;
            middle_click_paste = false;
          };

          ecosystem = {
            no_update_news = true;
            no_donation_nag = true;
          };

          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];

          bind = [
            "$mod, Return, exec, $terminal"
            "$mod, D, exec, $applicationLauncher"
            "$mod, Q, exec, $screenshot"

            "$mod, w, killactive"
            "$mod, s, togglefloating"
            "$mod, f, fullscreen"
            "$mod, m, fullscreen, 1"

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

          windowrulev2 = [
            "float, class:^(gnome-calculator|org\\.gnome\\.Calculator)$"
            "float, initialClass:^(nm-openconnect-auth-dialog)$"
            "pin, initialClass:^(nm-openconnect-auth-dialog)$"
            "center 1, initialClass:^(nm-openconnect-auth-dialog)$"

            "noborder, onworkspace:w[t1], floating:0"
            "rounding 0, onworkspace:w[t1], floating:0"
            "noshadow, onworkspace:w[t1], floating:0"

            "suppressevent maximize, class:^(.*)$"

            "size 640 510, initialClass:^(nm-openconnect-auth-dialog)$"

            "tag +tempfloat, initialTitle:^(Open File)$"
            "tag +tempfloat, class:^(nm-connection-editor|pavucontrol)$"
            "float, tag:tempfloat"
            "size 45% 45%, tag:tempfloat"
          ];

          workspace = [
            "w[t1], gapsout:0"
          ];
        };

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
  };
}
