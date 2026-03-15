{
  config,
  lib,
  ...
}:
let
  cfg = config.nixdots.gui.base.displayManager;
in
{
  options.nixdots.gui.base.displayManager = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.nixdots.gui.enableBase;
      description = "Whether to enable nixdots.gui.base.displayManager";
    };

    implementation = lib.mkOption {
      type = lib.types.enum [
        "ly"
        "gdm"
      ];
      default = "ly";
      description = "Which display manager implementation to use";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # LY – TUI display manager
      (lib.mkIf (cfg.implementation == "ly") {
        services.displayManager.ly = {
          enable = true;
          settings = {
            allow_empty_password = false;
            clear_password = true;
            session_log = "null";
          };
        };
      })

      # GDM – GNOME Display Manager
      (lib.mkIf (cfg.implementation == "gdm") {
        services.displayManager.gdm = {
          enable = true;
          wayland = true;
          autoSuspend = false;
          settings = { };
        };
      })
    ]
  );
}
