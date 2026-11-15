root@{ lib, ... }:
let
  adw = root.config.palettes.adwaita;
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
      label = {
        monitor = "";
        color = "rgb(${hex adw.windowFg})";
        font_family = "Adwaita Sans";
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
          background = {
            monitor = "";
            path = "${./assets/lockscreen-background.jpg}";
          };

          general.hide_cursor = true;
          animations.enabled = false;

          label = [
            (
              label
              // {
                text = "$TIME";
                font_size = 50;
                position = "0, 200";
              }
            )
            (
              label
              // {
                text = "cmd[update:1000] ${pkgs.coreutils}/bin/date +'%A, %B %d'";
                font_size = 30;
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
            inner_color = "rgba(${hex adw.windowFg}1a)";
            check_color = "rgb(${hex adw.accentBg})";
            fail_color = "rgb(${hex adw.errorBg})";
            font_color = "rgb(${hex adw.windowFg})";
            font_family = "Adwaita Sans";
            # hyprlang treats an unescaped # as a comment; ## is a literal #
            placeholder_text = "<i><span foreground=\"##${hex adw.windowFg}8c\">Enter Pass</span></i>";
            fail_text = "<i><span foreground=\"##${hex adw.error}\">$FAIL</span> <b>($ATTEMPTS)</b></i>";
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
