{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.nixdots.gui.desktops.hyprland.hyprdynamicmonitors;

  validProfiles = lib.filterAttrs (name: _: lib.hasSuffix ".conf" name || lib.hasSuffix ".go.tmpl" name) cfg.profiles;

  profileFiles = lib.mapAttrs' (name: contents: {
    name = "hyprdynamicmonitors/hyprconfigs/${name}";
    value = {
      text = contents;
    };
  }) validProfiles;
in
{
  options.nixdots.gui.desktops.hyprland.hyprdynamicmonitors = {
    enable = lib.mkEnableOption "nixdots.gui.desktops.hyprland.hyprdynamicmonitors";

    profiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = "Hyprdynamicmonitors profile configs written as .conf or .go.tmpl files in hyprconfigs";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra config to append to hyprdynamicmonitors";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.leier = {
      xdg.configFile = lib.mkMerge [
        {
          "hyprdynamicmonitors/config.toml".text = ''
            [general]
            destination = "$HOME/.config/hypr/monitors.conf"

            [fallback_profile]
            config_file = "fallback.conf"
            config_file_type = "static"

            ${cfg.extraConfig}
          '';

          "hyprdynamicmonitors/fallback.conf".text = ''
            # Generic fallback: configure all connected monitors with preferred settings
            monitor=,preferred,auto,1
          '';
        }
        profileFiles
      ];

      wayland.windowManager.hyprland = {
        extraConfig = ''
          # source the auto-generated monitors configuration
          source = ~/.config/hypr/monitors.conf
        '';

        settings.exec = [
          "pidof ${pkgs.unstable.hyprdynamicmonitors}/bin/hyprdynamicmonitors || ${pkgs.unstable.hyprdynamicmonitors}/bin/hyprdynamicmonitors run"
        ];
      };

      home.packages = [
        pkgs.unstable.hyprdynamicmonitors
      ];
    };
  };
}
