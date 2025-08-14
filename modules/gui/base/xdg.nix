{ config, lib, pkgs, ... }:
let
  cfg = config.dots.gui.xdg;
in
{
  options.dots.gui.xdg.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.dots.gui.enable;
  };

  config = lib.mkIf cfg.enable {
    home-manager.sharedModules = [
      ({ ... }@home_manager_inputs: {
        xdg = {
          enable = true;
          userDirs = {
            enable = true;
            createDirectories = true;
            desktop = "${home_manager_inputs.config.home.homeDirectory}/Desktop";
            download = "${home_manager_inputs.config.home.homeDirectory}/Downloads";
            music = "${home_manager_inputs.config.home.homeDirectory}/Music";
            pictures = "${home_manager_inputs.config.home.homeDirectory}/Pictures";
            videos = "${home_manager_inputs.config.home.homeDirectory}/Videos";
            documents = "${home_manager_inputs.config.home.homeDirectory}/Documents";
            publicShare = "${home_manager_inputs.config.home.homeDirectory}/Documents/Public";
            templates = "${home_manager_inputs.config.home.homeDirectory}/Documents/Templates";
          };
          mimeApps = {
            enable = true;
            defaultApplications = {
              "text/html" = "firefox.desktop";
              "x-scheme-handler/http" = "firefox.desktop";
              "x-scheme-handler/https" = "firefox.desktop";
              "x-scheme-handler/about" = "firefox.desktop";
              "x-scheme-handler/unknown" = "firefox.desktop";
              "application/pdf" = "firefox.desktop";
              "image/png" = "firefox.desktop";
              "image/jpeg" = "firefox.desktop";
            };
          };
        };
      })
    ];
  };
}
