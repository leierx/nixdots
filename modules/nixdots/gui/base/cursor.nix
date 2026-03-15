{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.gui.base.cursor;
in
{
  options.nixdots.gui.base.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.nixdots.gui.enableBase;
      description = "Whether to enable nixdots.gui.base.cursor";
    };

    size = lib.mkOption {
      type = lib.types.int;
      default = 24;
      description = "Cursor size in pixels";
    };

    theme = {
      name = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "Adwaita";
        description = "Cursor theme name";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.adwaita-icon-theme;
        description = "Package providing the cursor theme";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.leier = {
      home.pointerCursor = {
        name = cfg.theme.name;
        size = cfg.size;
        package = cfg.theme.package;

        x11 = {
          enable = true;
          defaultCursor = "left_ptr";
        };

        gtk.enable = true;
      };

      home.sessionVariables = {
        XCURSOR_THEME = cfg.theme.name;
        XCURSOR_SIZE = toString cfg.size;
      };
    };
  };
}
