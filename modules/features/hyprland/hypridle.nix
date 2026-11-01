{
  flake.modules.homeManager.hyprland =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      dpms =
        action:
        "${lib.getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";
    in
    {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = dpms "on";
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
              on-timeout = dpms "off";
              on-resume = dpms "on";
            }
          ];
        };
      };
    };
}
