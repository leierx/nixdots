{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.nixdots.gui.desktops.hyprland.hyprpaper;
in
{
  options.nixdots.gui.desktops.hyprland.hyprpaper = {
    enable = lib.mkEnableOption "nixdots.gui.desktops.hyprland.hyprpaper";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.leier = {
      services.hyprpaper = {
        enable = true;
        settings = {
          ipc = false; # disable IPC because I dont need it + battery consumption
          splash = false;
          preload = "${./assets/hyprland-wallpaper.png}";
          wallpaper = ",${./assets/hyprland-wallpaper.png}";
        };
      };

      # disable the systemd service that comes with hyprpaper
      systemd.user.services.hyprpaper = lib.mkForce { };

      wayland.windowManager.hyprland.settings.exec = [
        "pidof ${pkgs.hyprpaper}/bin/hyprpaper || ${pkgs.hyprpaper}/bin/hyprpaper"
      ];
    };
  };
}
