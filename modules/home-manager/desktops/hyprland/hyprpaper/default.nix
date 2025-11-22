{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.dots.homeManager.desktops.hyprland.hyprpaper.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = false; # disable IPC because I dont need it + battery consumption
        splash = false;
        preload = "${./wallpaper.png}";
        wallpaper = ",${./wallpaper.png}";
      };
    };

    # disable the systemd service that comes with hyprpaper
    systemd.user.services.hyprpaper = lib.mkForce {};

    wayland.windowManager.hyprland.settings.exec = [ "pidof ${pkgs.hyprpaper}/bin/hyprpaper || ${pkgs.hyprpaper}/bin/hyprpaper" ];
  };
}
