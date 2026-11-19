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
      idle =
        call: "${lib.getExe' config.programs.quickshell.package "qs"} ipc -c shell call idle ${call}";
      lockAfter = 300;
      fadeFor = 10;
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
            # the shell only draws the fade; input during it resumes this listener, which cancels it
            {
              timeout = lockAfter - fadeFor;
              on-timeout = idle "fade ${toString fadeFor}";
              on-resume = idle "cancel";
            }
            {
              timeout = lockAfter;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 360;
              on-timeout = dpms "off";
              on-resume = dpms "on";
            }
          ];
        };
      };
    };
}
