{
  modules.nixos.hyprland.security.pam.services.hyprlock = { };

  modules.homeManager.hyprland =
    { pkgs, lib, ... }:
    {
      wayland.windowManager.hyprland.settings.lockscreen_cmd._var = "${lib.getExe pkgs.hyprlock}";

      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            disable_loading_bar = true;
            grace = 0;
            hide_cursor = true;
            no_fade_in = false;
          };

          background = [
            {
              path = "screenshot";
              blur_passes = 3;
              blur_size = 8;
            }
          ];

          input-field = [
            {
              size = "200, 50";
              position = "0, -80";
              monitor = "";
              dots_center = true;
              fade_on_empty = false;
              font_color = "rgb(202, 211, 245)";
              inner_color = "rgb(91, 96, 120)";
              outer_color = "rgb(24, 25, 38)";
              outline_thickness = 5;
              placeholder_text = "Password...";
              shadow_passes = 2;
            }
          ];

          auth = {
            "pam:enabled" = true;
            "pam:module" = "hyprlock";
          };
        };
      };
    };
}
