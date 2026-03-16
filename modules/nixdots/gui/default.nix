{
  config,
  lib,
  ...
}:
let
  cfg = config.nixdots.gui;
in
{
  imports = [
    ./base
    ./desktops
  ];

  options.nixdots.gui = {
    enable = lib.mkEnableOption "nixdots.gui";

    enableBase = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      description = "Whether to enable nixdots.gui.base modules";
    };

    displayManager = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "ly"
          "gdm"
        ]
      );
      default = "ly";
      description = "Which display manager implementation to use";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # LY – TUI display manager
      (lib.mkIf (cfg.displayManager == "ly") {
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
      (lib.mkIf (cfg.displayManager == "gdm") {
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
