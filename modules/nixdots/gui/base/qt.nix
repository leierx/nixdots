{ config, lib, ... }:
let
  cfg = config.nixdots.gui.base.qt;
in
{
  options.nixdots.gui.base.qt = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.nixdots.gui.enableBase;
      description = "Whether to enable nixdots.gui.base.qt";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.leier.qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style.name = "adwaita-dark";
    };
  };
}
