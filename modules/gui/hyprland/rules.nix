{
  flake.modules.homeManager.hyprland = {
    wayland.windowManager.hyprland = {
      settings = {
        windowrulev2 = [
          "float, initialClass:^(nm-openconnect-auth-dialog)$"
          "pin, initialClass:^(nm-openconnect-auth-dialog)$"
          "center 1, initialClass:^(nm-openconnect-auth-dialog)$"
          "size 640 510, initialClass:^(nm-openconnect-auth-dialog)$"

          "suppressevent maximize, class:^(.*)$"

          # smart gaps / no gaps when only
          "bordersize 0, floating:0, onworkspace:w[t1]"
          "rounding 0, floating:0, onworkspace:w[t1]"
          "bordersize 0, floating:0, onworkspace:w[tg1]"
          "rounding 0, floating:0, onworkspace:w[tg1]"
          "bordersize 0, floating:0, onworkspace:f[1]"
          "rounding 0, floating:0, onworkspace:f[1]"
        ];

        # not available yet :(
        # windowrule = [
        #   {
        #     name = "steam main window";
        #     "match:class" = "steam";
        #     "match:title" = "Steam";
        #     tile = "on";
        #   }
        # ];

        workspace = [
          # smart gaps / no gaps when only
          "w[t1], gapsout:0" # no gaps when only
        ];
      };
    };
  };
}
