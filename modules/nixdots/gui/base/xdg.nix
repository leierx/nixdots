{ config, lib, ... }:
let
  cfg = config.nixdots.gui.base.xdg;
in
{
  options.nixdots.gui.base.xdg = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.nixdots.gui.enableBase;
      description = "Whether to enable nixdots.gui.base.xdg";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.leier.imports = [
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
