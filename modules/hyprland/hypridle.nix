{
  flake.modules.homeManager.hyprland =
    { pkgs, lib, ... }:
    {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
            ignore_dbus_inhibit = false;
            lock_cmd = "${lib.getExe pkgs.hyprlock}";
            inhibit_sleep = 3;
          };
          listener = [
            {
              timeout = 300; # 5 minutes
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 360; # 6 minutes
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };

      # disable the home-manager systemd service
      systemd.user.services.hypridle = lib.mkForce { };

      # autostart
      wayland.windowManager.hyprland.settings.exec-once = [ "${lib.getExe pkgs.hypridle}" ];
    };
}
