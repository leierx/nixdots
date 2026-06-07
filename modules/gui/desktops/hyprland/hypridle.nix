{
  modules.homeManager.hyprland =
    { pkgs, lib, ... }:
    {
      services.hypridle = {
        enable = true;
        systemdTarget = "hyprland-session.target";
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
    };
}
