root@{ lib, ... }:
let
  ui = root.config.palettes.ui;
  hex = lib.removePrefix "#";
in
{
  flake.modules.homeManager.hyprland =
    {
      config,
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      fingerprint = osConfig.services.fprintd.enable;
      label = {
        monitor = "";
        color = "rgba(${hex ui.fg}bf)";
        font_family = "Hack";
        halign = "center";
        valign = "center";
      };
    in
    {
      wayland.windowManager.hyprland.settings.lockscreen_cmd._var =
        lib.getExe config.programs.hyprlock.package;

      programs.hyprlock = {
        enable = true;
        settings = {
          background = {
            monitor = "";
            path = "${./assets/lockscreen-background.jpg}";
          };

          general = {
            no_fade_in = true;
            no_fade_out = true;
            disable_loading_bar = true;
            hide_cursor = true;
          };

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
            inner_color = "rgba(${hex ui.white}1a)";
            font_color = "rgb(${hex ui.fg})";
            font_family = "Hack";
            # hyprlang treats an unescaped # as a comment; ## is a literal #.
            placeholder_text = "<i><span foreground=\"##${hex ui.fg}99\">Enter Pass</span></i>";
            fail_text = "<i><span foreground=\"##${hex ui.redLight}cc\">$FAIL</span> <b>($ATTEMPTS)</b></i>";
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
