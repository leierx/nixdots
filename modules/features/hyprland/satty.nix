root: {
  flake.modules.homeManager.hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      adw = root.config.palettes.adwaita_darker;
    in
    {
      programs.satty = {
        enable = true;
        settings = {
          general = {
            output-filename = "${config.xdg.userDirs.pictures}/screenshots/%Y%m%d-%H%M%S.png";
            # GTK's own clipboard empties as Satty exits
            copy-command = lib.getExe' pkgs.wl-clipboard "wl-copy";
            early-exit = true;
            actions-on-enter = [ "save-to-clipboard" ];
            actions-on-escape = [ "exit" ];
            initial-tool = "rectangle";
            no-window-decoration = true;
          };
          # the first is the one selected
          color-palette.palette = [
            adw.red_3
            adw.orange_3
            adw.yellow_3
            adw.green_3
            adw.blue_3
          ];
        };
      };

      # above the GTK theme, whose button sizes Satty's own overrides.css cannot beat; only Satty's window has the "root" class
      gtk.gtk4.extraCss = ''
        window.root .toolbar { background: ${adw.popover_bg_color}; padding: 8px; }
        window.root .toolbar button { min-width: 48px; min-height: 48px; padding: 4px; }
        window.root .toolbar button image { -gtk-icon-size: 32px; }
        window.root .toolbar label { font-size: 1.4em; }
      '';

      wayland.windowManager.hyprland.settings.window_rule = [
        {
          match.class = "^com\\.gabm\\.satty$";
          # no parent, so it would tile
          float = true;
          center = true;
          size = [
            "monitor_w*0.75"
            "monitor_h*0.75"
          ];
          dim_around = true;
          stay_focused = true;
        }
      ];
    };
}
