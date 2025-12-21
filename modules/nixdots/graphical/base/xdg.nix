{ config, lib, ... }:
let
  cfg = config.nixdots.graphical.base.xdg;
in
{
  options.nixdots.graphical.base.xdg = {
    enable = lib.mkEnableOption "Enable XDG user dirs";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${config.nixdots.core.primaryUser.username}.imports = [
      (
        { config, ... }:
        {
          xdg = {
            enable = true;

            userDirs = {
              enable = true;
              createDirectories = true;

              desktop = "${config.home.homeDirectory}/Desktop";
              download = "${config.home.homeDirectory}/Downloads";
              music = "${config.home.homeDirectory}/Music";
              pictures = "${config.home.homeDirectory}/Pictures";
              videos = "${config.home.homeDirectory}/Videos";
              documents = "${config.home.homeDirectory}/Documents";
              publicShare = "${config.home.homeDirectory}/Documents/Public";
              templates = "${config.home.homeDirectory}/Documents/Templates";
            };
          };
        }
      )
    ];
  };
}
