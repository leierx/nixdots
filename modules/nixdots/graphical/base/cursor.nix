{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.graphical.base.cursor;
in
{
  options.nixdots.graphical.base.cursor = {
    enable = lib.mkEnableOption "Enable global cursor configuration (de-agnostic)";

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
    home-manager.users.${config.nixdots.core.primaryUser.username} = {
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
