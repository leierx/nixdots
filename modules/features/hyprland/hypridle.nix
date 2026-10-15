{
  flake.modules.homeManager.hyprland =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
            ignore_dbus_inhibit = false;
            # one locker even when the idle timer and before_sleep_cmd race
            lock_cmd = "${lib.getExe' pkgs.procps "pidof"} hyprlock || ${lib.getExe config.programs.hyprlock.package}";
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
