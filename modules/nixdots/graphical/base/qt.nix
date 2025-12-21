{ config, lib, ... }:
let
  cfg = config.nixdots.graphical.base.qt;
in
{
  options.nixdots.graphical.base.qt = {
    enable = lib.mkEnableOption "Enable Qt theming defaults";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${config.nixdots.core.primaryUser.username}.qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style.name = "adwaita-dark";
    };
  };
}
