root@{ lib, ... }:
let
  adw = root.config.palettes.adwaita_darker;
  hex = lib.removePrefix "#";
in
{
  flake.modules.homeManager.hyprland =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      fingerprint = osConfig.services.fprintd.enable;
      font = "Adwaita Sans";
      label = {
        monitor = "";
        color = "rgb(${hex adw.window_fg_color})";
        font_family = font;
        halign = "center";
        valign = "center";
      };
    in
    {
      # the labels' font_family
      home.packages = [ pkgs.adwaita-fonts ];

      programs.hyprlock = {
        enable = true;
        settings = {
          # each screen as it was, dim included; hypridle's lock command evens out the dim
          background = {
            monitor = "";
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
            brightness = 0.6;
            # 1 keeps brightness a plain multiply
            contrast = 1;
            vibrancy = 0.2;
            noise = 0.01;
            # without screencopy
            color = "rgb(${hex adw.dark_5})";
          };

          general.hide_cursor = true;
          # fadeIn starts from the screenshot, so the lock takes over without an edge
          animations = {
            enabled = true;
            bezier = "out, 0.2, 0, 0, 1";
            animation = [
              "fadeIn, 1, 6, out"
              # it would fade back to the screenshot, dim and all, then cut to the desktop
              "fadeOut, 0"
            ];
          };

          label = [
            (
              label
              // {
                text = "$TIME";
                font_family = "${font} Bold";
                font_size = 64;
                position = "0, 185";
              }
            )
            (
              label
              // {
                text = "cmd[update:1000] ${pkgs.coreutils}/bin/date +'%A %-d %B'";
                font_size = 24;
                position = "0, 100";
              }
            )
          ]
          ++ lib.optional fingerprint (
            label
            // {
              text = "$FPRINTPROMPT";
              font_size = 14;
              position = "0, -170";
            }
          );

          input-field = {
            monitor = "";
            size = "320, 55";
            dots_center = true;
            dots_size = 0.2;
            dots_spacing = 0.2;
            outer_color = "rgba(00000000)";
            inner_color = "rgba(${hex adw.window_fg_color}1a)";
            check_color = "rgb(${hex adw.accent_bg_color})";
            fail_color = "rgb(${hex adw.error_bg_color})";
            font_color = "rgb(${hex adw.window_fg_color})";
            font_family = font;
            # hyprlang treats an unescaped # as a comment; ## is a literal #
            placeholder_text = "<i><span foreground=\"##${hex adw.window_fg_color}8c\">Password</span></i>";
            fail_text = "<i><span foreground=\"##${hex adw.error_color}\">$FAIL</span> <b>($ATTEMPTS)</b></i>";
            hide_input = false;
            position = "0, -100";
            halign = "center";
            valign = "center";
          };
        }
        // lib.optionalAttrs fingerprint { auth."fingerprint:enabled" = true; };
      };
    };
}
