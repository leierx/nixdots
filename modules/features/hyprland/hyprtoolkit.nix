root@{ lib, ... }:
let
  adw = root.config.palettes.adwaita_darker;
  hex = lib.removePrefix "#";
  # libadwaita draws these as the foreground at a percentage; hyprtoolkit brightens them, so they must be opaque
  over =
    fg: percent: bg:
    lib.concatMapStrings
      (
        i:
        let
          channel = c: lib.fromHexString (builtins.substring i 2 (hex c));
        in
        lib.fixedWidthString 2 "0" (
          lib.toHexString ((channel bg * (100 - percent) + channel fg * percent + 50) / 100)
        )
      )
      [
        0
        2
        4
      ];
  rgb = c: "rgb(${c})";
in
{
  flake.modules.homeManager.hyprland =
    { pkgs, ... }:
    {
      # the fonts and icon theme the config names
      home.packages = [
        pkgs.adwaita-fonts
        pkgs.papirus-icon-theme
      ];

      # hyprpolkitagent, hyprland-guiutils' dialogs and the other hyprtoolkit apps
      xdg.configFile."hypr/hyprtoolkit.conf".text = lib.generators.toKeyValue { } {
        background = rgb (hex adw.window_bg_color);
        base = rgb (over adw.window_fg_color 10 adw.window_bg_color);
        alternate_base = rgb (over adw.window_fg_color 15 adw.window_bg_color);
        text = rgb (hex adw.window_fg_color);
        bright_text = rgb (hex adw.accent_fg_color);
        link_text = rgb (hex adw.accent_color);
        # hyprtoolkit puts dark text on an accent lighter than OkLab 0.5, which accent_bg_color is
        accent = rgb (hex adw.blue_5);
        accent_secondary = rgb (hex adw.accent_color);
        rounding_small = 9;
        rounding_large = 12;
        font_family = "Adwaita Sans";
        font_family_monospace = "Adwaita Mono";
        icon_theme = "Papirus-Dark";
      };
    };
}
