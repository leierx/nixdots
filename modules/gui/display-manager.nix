{ config, lib, ... }:
let
  cfg = config.dots.gui.displayManager;
in
{
  options.dots.gui.displayManager = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.dots.gui.enable;
    };

    implementation = lib.mkOption {
      type = lib.types.enum [ "ly" "gdm" ];
      default = "ly";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # LY - a TUI display manager
    ( lib.mkIf (cfg.implementation == "ly") {
      services.displayManager.ly = {
        enable = true;
        settings = { hide_borders = true; };
      };
    })

    # GDM - The GNOME Display Manager
    ( lib.mkIf (cfg.implementation == "gdm") {
      services.xserver.displayManager.gdm = {
        enable = true;
        wayland = true;
        autoSuspend = false;
        settings = {};
      };
    })
  ]);
}
