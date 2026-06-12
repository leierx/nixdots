{
  modules.homeManager.hyprland = {
    wayland.windowManager.hyprland = {
      settings = {
        window_rule = [
          {
            match.initial_class = "^(nm-openconnect-auth-dialog|nm-connection-editor)$";
            float = true;
            pin = true;
            center = true;
            size = [
              640
              510
            ];
          }
          {
            match.class = ".*";
            suppress_event = "maximize";
          }
          # smart gaps / no gaps when single client
          {
            match = {
              workspace = "w[t1]";
              float = false;
            };
            border_size = 0;
            rounding = 0;
            no_shadow = true;
          }
          {
            match = {
              workspace = "w[tg1]";
              float = false;
            };
            border_size = 0;
            rounding = 0;
          }
          {
            match = {
              workspace = "f[1]";
              float = false;
            };
            border_size = 0;
            rounding = 0;
          }
        ];

        workspace_rule = [
          {
            workspace = "w[t1]";
            gaps_out = 0;
            gaps_in = 0;
          }
          {
            workspace = "w[tg1]";
            gaps_out = 0;
            gaps_in = 0;
          }
          {
            workspace = "f[1]";
            gaps_out = 0;
            gaps_in = 0;
          }
        ];
        layer_rule = [
          {
            match.namespace = "rofi";
            dim_around = true;
          }
        ];
      };

      extraConfig = "";
    };
  };
}
