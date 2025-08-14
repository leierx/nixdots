{ config, pkgs, lib, ... }:
let
  cfg = config.dots.gui.qt;
in
{
  options.dots.gui.qt.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.dots.gui.enable;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ qgnomeplatform qgnomeplatform-qt6 adwaita-qt adwaita-qt6 ];

    qt = {
      enable = true;
      style = "adwaita-dark";
    };

    home-manager.sharedModules = [
      ({
        qt = {
          enable = true;
          platformTheme.name = "adwaita";
          style.name = "adwaita-dark";
        };
      })
    ];
  };
}
