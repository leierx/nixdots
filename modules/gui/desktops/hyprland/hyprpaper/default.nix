{ config, lib, pkgs, ... }:
let
  theme = config.dots.theme;
in
{
  config = lib.mkIf config.dots.gui.hyprland.hyprpaper.enable {
    environment.systemPackages = [ pkgs.hyprpaper ];

    home-manager.sharedModules = [
      ({
        services.hyprpaper = {
          enable = true;
          settings = {
            ipc = false; # disable IPC because I dont need it + battery consumption
            splash = false;
            preload = "${theme.wallpaper}";
            wallpaper = ",${theme.wallpaper}";
          };
        };

        # disable the systemd service that comes with services.hyprpaper.enable
        systemd.user.services.hyprpaper = lib.mkForce { };

        wayland.windowManager.hyprland.settings.exec = [ "pidof hyprpaper || hyprpaper" ];
      })
    ];
  };
}
