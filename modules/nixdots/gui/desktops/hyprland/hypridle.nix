{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.nixdots.gui.desktops.hyprland.hypridle;
in
{
  options.nixdots.gui.desktops.hyprland.hypridle = {
    enable = lib.mkEnableOption "nixdots.gui.desktops.hyprland.hypridle";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.leier = {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
            ignore_dbus_inhibit = false;
            lock_cmd = "pidof hyprlock || hyprlock";
            inhibit_sleep = 3;
          };

          listener = [
            # 5 minutes
            {
              timeout = 300;
              on-timeout = "loginctl lock-session";
            }
            # 6 minutes
            {
              timeout = 360;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };

      # disable the systemd service that comes with hypridle
      systemd.user.services.hypridle = lib.mkForce { };

      # autostart
      wayland.windowManager.hyprland.settings.exec = [
        "pidof ${pkgs.hypridle}/bin/hypridle || ${pkgs.hypridle}/bin/hypridle"
      ];
    };
  };
}
