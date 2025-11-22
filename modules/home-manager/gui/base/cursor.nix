{ config, lib, pkgs, ... }:
let
  cfg = config.dots.homeManager.gui.base.cursor;
in
  {
  options.dots.homeManager.gui.base.cursor = {
    size = lib.mkOption { type = lib.types.int; default = 24; };
    theme.name = lib.mkOption { type = lib.types.singleLineStr; default = "Adwaita"; };
    theme.package = lib.mkOption { type = lib.types.package; default = pkgs.adwaita-icon-theme; };
  };

  config = {
    home.pointerCursor = {
      name = cfg.theme.name;
      size = cfg.size;
      package = cfg.theme.package;
      x11 = {
        enable = true;
        defaultCursor = "left_ptr";
      };
      gtk.enable = true;
    };

    wayland.windowManager.hyprland.settings.env = [
      "HYPRCURSOR_THEME,${cfg.theme.name}"
      "HYPRCURSOR_SIZE,${toString cfg.size}"
    ];

    wayland.windowManager.hyprland.settings.exec-once = [
      "hyprctl setcursor ${cfg.theme.name} ${toString cfg.size}"
    ];
  };
}
