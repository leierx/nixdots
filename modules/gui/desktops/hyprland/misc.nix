{
  flake.modules.homeManager.hyprland = {
    wayland.windowManager.hyprland = {
      settings = {
        general = {
          border_size = 2;
          "col.inactive_border" = "rgb(595959)";
          "col.active_border" = "rgb(2bbf3e) rgb(2bbf3e) rgb(2bbf3e) rgb(0e66d0) rgb(0e66d0) rgb(0e66d0) 30deg";
          gaps_in = 10;
          gaps_out = 20;
          layout = "dwindle";
        };

        dwindle.force_split = 2;

        decoration = {
          rounding = 10;
          rounding_power = 2.0;

          blur.enabled = false;

          shadow = {
            enabled = true;
            ignore_window = true;
            range = 40;
            render_power = 6;
            offset = "0 0";
            color = "rgba(0, 0, 0, 0.9)";
          };
        };

        animations.enabled = false;

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          force_default_wallpaper = 0;
          focus_on_activate = true;
          middle_click_paste = false;
        };

        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
      };
    };
  };
}
