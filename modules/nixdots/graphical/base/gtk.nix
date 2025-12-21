{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.graphical.base.gtk;
in
{
  options.nixdots.graphical.base.gtk = {
    enable = lib.mkEnableOption "Enable GTK config & theming";

    font = {
      name = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "gnome";
        description = "GTK font name";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.cantarell-fonts;
        description = "Font package to install for GTK";
      };

      size = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Font size (null to let GTK/DE decide)";
      };
    };

    theme = {
      name = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "adw-gtk3-dark";
        description = "GTK theme name";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.adw-gtk3;
        description = "Package providing the GTK theme";
      };
    };

    iconTheme = {
      name = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "Papirus-Dark";
        description = "GTK icon theme name";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.papirus-icon-theme;
        description = "Package providing the icon theme";
      };
    };

    preferDark = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Prefer dark theme for GTK apps";
    };

    enableAnimations = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GTK animations";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${config.nixdots.core.primaryUser.username} = {
      dconf.enable = true;
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = if cfg.preferDark then "prefer-dark" else "default";
        };
      };

      gtk = {
        enable = true;

        font = { inherit (cfg.font) name package size; };
        theme = { inherit (cfg.theme) name package; };
        iconTheme = { inherit (cfg.iconTheme) name package; };

        gtk3 = {
          bookmarks = [ ];
          extraConfig = {
            gtk-application-prefer-dark-theme = if cfg.preferDark then 1 else 0;
            gtk-enable-animations = if cfg.enableAnimations then 1 else 0;
            gtk-enable-primary-paste = 0;
            gtk-recent-files-enabled = 0;
            gtk-enable-event-sounds = 0;
            gtk-enable-input-feedback-sounds = 0;
            gtk-error-bell = 0;
          };
        };

        gtk4 = {
          extraConfig = {
            gtk-application-prefer-dark-theme = if cfg.preferDark then 1 else 0;
            gtk-enable-animations = if cfg.enableAnimations then 1 else 0;
            gtk-enable-primary-paste = 0;
            gtk-recent-files-enabled = 0;
            gtk-enable-event-sounds = 0;
            gtk-enable-input-feedback-sounds = 0;
            gtk-error-bell = 0;
          };
        };
      };
    };
  };
}
