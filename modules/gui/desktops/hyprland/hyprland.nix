{ config, inputs, ... }:
let
  outerConfig = config;
in
{
  modules.nixos.hyprland =
    { pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        xwayland.enable = true;
      };

      nix.settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      };

      services.gvfs.enable = true;
      services.gnome.sushi.enable = true;
      environment.systemPackages = [ pkgs.nautilus ];

      home-manager.sharedModules = [ outerConfig.modules.homeManager.hyprland ];
    };

  modules.homeManager.hyprland =
    {
      pkgs,
      osConfig,
      lib,
      ...
    }:
    {
      imports = [
        outerConfig.modules.homeManager.wezterm
        outerConfig.modules.homeManager.rofi
      ];

      home.packages = [ pkgs.wl-clipboard ];

      xdg.portal = {
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
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
        portalPackage = osConfig.programs.hyprland.portalPackage;
        # systemd.variables = [ "--all" ];
        settings = {
          # Variables
          mod._var = "SUPER";
          terminal_cmd._var = "wezterm";
          applicationLauncher_cmd._var = "rofi -modes drun -show drun";

          config = {
            general = {
              border_size = 2;
              gaps_in = 10;
              gaps_out = 15;
              col = {
                inactive_border = "rgb(595959)";
                active_border = {
                  colors = [
                    "rgb(2bbf3e)"
                    "rgb(2bbf3e)"
                    "rgb(2bbf3e)"
                    "rgb(0e66d0)"
                    "rgb(0e66d0)"
                    "rgb(0e66d0)"
                  ];
                  angle = 30;
                };
                nogroup_border = "0xffffaaff";
                nogroup_border_active = "0xffff00ff";
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

            misc = {
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              font_family = "Sans";
              force_default_wallpaper = 0;
              disable_autoreload = true;
              focus_on_activate = true;
              background_color = "0x1C1C1C";
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
              mkExecOnStart = cmd: {
                _args = [
                  "hyprland.start"
                  (mkLuaInline "function() hl.exec_cmd(${builtins.toJSON cmd}) end")
                ];
              };
            in
            [
              (mkExecOnStart "vesktop")
              (mkExecOnStart "firefox")
              (mkExecOnStart "${pkgs.wbg}/bin/wbg ${./assets/wallpaper.png}")
            ]
            ++ lib.optional osConfig.networking.networkmanager.enable (
              mkExecOnStart "${pkgs.networkmanagerapplet}/bin/nm-applet"
            );
        };
      };
    };
}
