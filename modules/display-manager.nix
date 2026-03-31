{ config, lib, ... }:
{
  flake.modules.nixos.displayManager =
    let
      displayManager = config.flake.settings.gui.displayManager;
    in
    lib.mkMerge [
      (lib.mkIf (displayManager == "ly") {
        services.displayManager.ly = {
          enable = true;
          settings = {
            allow_empty_password = false;
            clear_password = true;
            session_log = "null";
          };
        };
      })
      (lib.mkIf (displayManager == "gdm") {
        services.displayManager.gdm = {
          enable = true;
          wayland = true;
          autoSuspend = false;
          settings = { };
        };
      })
    ];
}
