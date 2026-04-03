{
  flake.modules.homeManager.hyprland = {
    wayland.windowManager.hyprland = {
      settings = {
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        bind = [
          "$mod, Return, exec, $terminal"
          "$mod, D, exec, $applicationLauncher"
          "$mod, Q, exec, $screenshot"

          "$mod, w, killactive"
          "$mod, s, togglefloating"
          "$mod, f, fullscreen"
          "$mod, m, fullscreen, 1"

          "$mod, 1, split:workspace, 1"
          "$mod, 2, split:workspace, 2"
          "$mod, 3, split:workspace, 3"
          "$mod, 4, split:workspace, 4"
          "$mod, 5, split:workspace, 5"
          "$mod, 6, split:workspace, 6"

          "$mod SHIFT, 1, split:movetoworkspacesilent, 1"
          "$mod SHIFT, 2, split:movetoworkspacesilent, 2"
          "$mod SHIFT, 3, split:movetoworkspacesilent, 3"
          "$mod SHIFT, 4, split:movetoworkspacesilent, 4"
          "$mod SHIFT, 5, split:movetoworkspacesilent, 5"
          "$mod SHIFT, 6, split:movetoworkspacesilent, 6"

          "$mod, O, focusmonitor, +1"
          "$mod SHIFT, O, movewindow, mon:+1"

          "$mod, C, cyclenext"
          "$mod SHIFT, C, swapnext"

          "$mod, h, movefocus, l"
          "$mod, l, movefocus, r"
          "$mod, k, movefocus, u"
          "$mod, j, movefocus, d"

          "$mod SHIFT, h, movewindow, l"
          "$mod SHIFT, l, movewindow, r"
          "$mod SHIFT, k, movewindow, u"
          "$mod SHIFT, j, movewindow, d"
        ];
      };

      extraConfig = ''
        # WM control center submap
        bind = $mod, X, exec, sleep 2 && hyprctl dispatch submap reset
        bind = $mod, X, submap, system_control
        submap = system_control

        # shut down computer
        bind = , ESCAPE, exec, systemctl poweroff
        bind = , ESCAPE, submap, reset

        # exit hyprland
        bind = , Q, exit
        bind = , Q, submap, reset

        # reload hyprland
        bind = , R, exec, hyprctl reload config-only
        bind = , R, submap, reset
        bind = $mod, R, exec, hyprctl reload
        bind = $mod, R, submap, reset

        # lockscreen
        bind = , L, exec, $lockscreen
        bind = , L, submap, reset

        bind = , catchall, submap, reset

        submap = reset
      '';
    };
  };
}
