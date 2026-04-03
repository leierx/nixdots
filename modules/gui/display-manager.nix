{ config, lib, ... }:
let
  displayManager = config.flake.meta.displayManager;
in
{
  flake.modules.nixos.displayManager =
    { lib, ... }:
    {

      config = lib.mkMerge [
        (lib.mkIf (displayManager.implementation == "ly") {
          services.displayManager.ly = {
            enable = true;
            settings = {
              allow_empty_password = false;
              clear_password = true;
              session_log = "null";
            };
          };
        })
        (lib.mkIf (displayManager.implementation == "gdm") {
          services.displayManager.gdm = {
            enable = true;
            wayland = true;
            autoSuspend = false;
            settings = { };
          };
        })
      ];
    };
}
