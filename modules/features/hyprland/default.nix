root@{ inputs, lib, ... }:
let
  ui = root.config.palettes.ui;
  hex = lib.removePrefix "#";
in
{
  flake.modules.nixos.hyprland =
    { pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        xwayland.enable = true;
      };

      hardware.graphics.enable = true;

      nix.settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      };

      services.gvfs.enable = true;
      services.gnome.sushi.enable = true;
      environment.systemPackages = [ pkgs.nautilus ];

      # hyprlock reads fprintd itself; pam_fprintd would block the password
      security.pam.services.hyprlock.fprintAuth = false;
    };

  flake.modules.homeManager.hyprland =
    {
      config,
      pkgs,
      osConfig,
      lib,
      ...
    }:
    {
      home.packages = with pkgs; [
        wl-clipboard
        wdisplays
      ];

      # session services run under Hyprland only
      wayland.systemd.target = "hyprland-session.target";

      services.cliphist = {
        enable = true;
        allowImages = true;
      };
      # cliphist's history persists in the cache dir; drop it on every login.
      systemd.user.tmpfiles.rules = [ "R %C/cliphist" ];

      services.hyprpolkitagent.enable = true;

      services.network-manager-applet.enable = osConfig.networking.networkmanager.enable;
      # its unit hardcodes graphical-session.target
      systemd.user.services.network-manager-applet = lib.mkIf osConfig.networking.networkmanager.enable {
        Unit.PartOf = lib.mkForce [ config.wayland.systemd.target ];
        Unit.After = lib.mkForce [
          config.wayland.systemd.target
          "tray.target"
        ];
        Install.WantedBy = lib.mkForce [ config.wayland.systemd.target ];
      };

      xdg.portal = {
        # home-manager's hyprland module turns this off when portalPackage is null
        enable = lib.mkForce true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          osConfig.programs.hyprland.portalPackage
        ];
        config = {
          hyprland = {
            default = [
              "hyprland"
              "gtk"
            ];
          };
        };
      };

      wayland.windowManager.hyprland = {
        enable = true;
        package = osConfig.programs.hyprland.package;
        # home-manager would pass this to `override { hyprland = …; }`, which the
        # xdph that Hyprland 0.57 pins no longer accepts.
        portalPackage = null;
        settings = {
          # Variables
          mod._var = "SUPER";

          config = {
            general = {
              border_size = 2;
              gaps_in = 10;
              gaps_out = 15;
              col = {
                inactive_border = "rgb(${hex ui.unfocusedBorderColor})";
                active_border = {
                  colors = [
                    "rgb(${hex ui.green})"
                    "rgb(${hex ui.green})"
                    "rgb(${hex ui.green})"
                    "rgb(${hex ui.focusedBorderColor})"
                    "rgb(${hex ui.focusedBorderColor})"
                    "rgb(${hex ui.focusedBorderColor})"
                  ];
                  angle = 30;
                };
                nogroup_border = "rgb(${hex ui.magenta})";
                nogroup_border_active = "rgb(${hex ui.magentaLight})";
              };
              layout = "dwindle"; # default layout
            };

            decoration = {
              rounding = 10;
              glow.enabled = false;
              blur.enabled = false;

              shadow = {
                enabled = true;
                range = 40;
                # render_power = 3;
                color = "rgba(0, 0, 0, 0.9)";
              };
            };

            animations.enabled = false;

            input = {
              kb_layout = osConfig.services.xserver.xkb.layout;
              kb_variant = osConfig.services.xserver.xkb.variant;
            };

            misc = {
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              font_family = "Sans";
              force_default_wallpaper = 0;
              disable_autoreload = true;
              focus_on_activate = true;
              background_color = "0x${hex ui.bg1}";
              on_focus_under_fullscreen = 0;
              middle_click_paste = false;
            };

            xwayland.enabled = true;

            ecosystem = {
              no_update_news = true;
              no_donation_nag = true;
              enforce_permissions = false; # I want to eventually! its a cool feature
            };

            dwindle.force_split = 2;
          };

          on =
            let
              inherit (lib.generators) mkLuaInline;
              mkExecOn = event: cmd: {
                _args = [
                  event
                  (mkLuaInline "function() hl.exec_cmd(${builtins.toJSON cmd}) end")
                ];
              };
            in
            [
              (mkExecOn "hyprland.start" "${lib.getExe pkgs.wbg} -s ${./assets/wallpaper.png}")
            ]
            # a config reload resets the outputs to Hyprland's monitor rules
            ++ lib.optional config.services.kanshi.enable (
              mkExecOn "config.reloaded" "${lib.getExe' config.services.kanshi.package "kanshictl"} reload"
            );
        };
      };
    };
}
