{
  config,
  lib,
  ...
}:
let
  cfg = config.nixdots.graphical.base.displayManager;
in
{
  options.nixdots.graphical.base.displayManager = {
    enable = lib.mkEnableOption "Enable display manager";

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
            hide_borders = true;
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
