{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.dots.homeManager.desktops.hyprland.hypridle.enable {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          before_sleep_cmd = "loginctl lock-session";
          # after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "pidof hyprlock || hyprlock";
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
    systemd.user.services.hypridle = lib.mkForce {};

    # autostart
    wayland.windowManager.hyprland.settings.exec = [ "pidof ${pkgs.hypridle}/bin/hypridle || ${pkgs.hypridle}/bin/hypridle" ];
  };
}
