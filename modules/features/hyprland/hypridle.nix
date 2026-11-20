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
      inherit (config.programs.hyprlock.settings.background) brightness;
      # The idle dim ends where the lock's background is, so the lock's fade-in only blurs.
      depth = 1 - brightness;

      lock = pkgs.writeShellApplication {
        name = "lock";
        runtimeInputs = [
          config.programs.hyprlock.package
          config.programs.quickshell.package
          pkgs.procps
          pkgs.gawk
          pkgs.gnused
          pkgs.coreutils
        ];
        text = ''
          # one locker even when the idle timer and before_sleep_cmd race
          pidof hyprlock > /dev/null && exit 0

          # hyprlock's screenshot takes in the shell's dim, so the shell holds it still and the lock's brightness makes up for it
          dark=$(timeout 2 qs ipc -c shell call idle hold 2> /dev/null) || dark=0
          config=${config.xdg.configFile."hypr/hyprlock.conf".source}
          if awk -v d="$dark" 'BEGIN { exit !(d > 0 && d < 1) }'; then
            even=$(awk -v d="$dark" -v b=${toString brightness} 'BEGIN { printf "%.4f", b / (1 - d) }')
            sed "s/^\([[:space:]]*brightness=\).*/\1$even/" "$config" > "$XDG_RUNTIME_DIR/hyprlock-dimmed.conf"
            config=$XDG_RUNTIME_DIR/hyprlock-dimmed.conf
          fi

          hyprlock -c "$config" || true
          # also when hyprlock never got the lock
          timeout 2 qs ipc -c shell call idle unlocked > /dev/null 2>&1 || true
        '';
      };
    in
    {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = dpms "on";
            ignore_dbus_inhibit = false;
            lock_cmd = lib.getExe lock;
            inhibit_sleep = 3;
            # under the lock, so unlocking shows the desktop undimmed
            on_lock_cmd = idle "locked";
            # an unlock without a key or the mouse (fingerprint) never resumes the fade's listener
            on_unlock_cmd = idle "unlocked";
          };
          listener = [
            # the shell only draws the fade; input during it resumes this listener, which cancels it
            {
              timeout = lockAfter - fadeFor;
              on-timeout = idle "fade ${toString fadeFor} ${toString depth}";
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
