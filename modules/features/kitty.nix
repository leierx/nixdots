root: {
  flake.modules.homeManager.kitty =
    { pkgs, ... }:
    let
      colors = root.config.palettes.adwaitaDarker;
    in
    {
      home.packages = [ pkgs.hack-font ];

      programs.kitty = {
        enable = true;
        shellIntegration.mode = null; # Keep HM out of my shell rc; kitty setting below wins.
        keybindings = {
          "ctrl+shift+c" = "copy_to_clipboard";
          "ctrl+shift+v" = "paste_from_clipboard";
          "ctrl+plus" = "change_font_size all +2.0";
          "ctrl+minus" = "change_font_size all -2.0";
          "ctrl+0" = "change_font_size all 0";
        };
        settings = {
          # Fonts
          font_family = "Hack";
          font_size = "16.0";
          # Text cursor customization
          cursor = colors.cursor; # Adwaita darker
          cursor_text_color = colors.cursorText; # Adwaita darker
          cursor_shape = "block";
          # Scrollback
          scrollback_lines = "10000"; # standard long scrollback
          scrollbar = "never"; # do not use scrollbar
          scrollbar_interactive = "no"; # do not use scrollbar
          # Mouse
          mouse_hide_wait = "0"; # never autohide
          url_color = colors.urlColor; # Adwaita darker
          copy_on_select = "yes";
          paste_actions = "no-op"; # hands off!
          # Mouse actions
          clear_all_mouse_actions = "no";
          # Terminal bell
          enable_audio_bell = "no"; # hands off!
          window_alert_on_bell = "no"; # hands off!
          macos_dock_badge_on_bell = "yes";
          # Window layout
          remember_window_size = "no"; # hands off!
          enabled_layouts = "splits"; # better than "all", no "disable"
          draw_minimal_borders = "no";
          active_border_color = colors.activeBorderColor; # Adwaita darker
          inactive_border_color = colors.inactiveBorderColor; # Adwaita darker
          bell_border_color = colors.bellBorderColor; # Adwaita darker
          confirm_os_window_close = "0"; # no confirm
          # Color scheme
          foreground = colors.foreground; # Adwaita darker
          background = colors.background; # Adwaita darker
          selection_foreground = colors.selectionForeground; # Adwaita darker
          selection_background = colors.selectionBackground; # Adwaita darker
          # The color table
          color0 = colors.black; # Adwaita darker
          color8 = colors.blackLight; # Adwaita darker
          color1 = colors.red; # Adwaita darker
          color9 = colors.redLight; # Adwaita darker
          color2 = colors.green; # Adwaita darker
          color10 = colors.greenLight; # Adwaita darker
          color3 = colors.yellow; # Adwaita darker
          color11 = colors.yellowLight; # Adwaita darker
          color4 = colors.blue; # Adwaita darker
          color12 = colors.blueLight; # Adwaita darker
          color5 = colors.magenta; # Adwaita darker
          color13 = colors.magentaLight; # Adwaita darker
          color6 = colors.cyan; # Adwaita darker
          color14 = colors.cyanLight; # Adwaita darker
          color7 = colors.white; # Adwaita darker
          color15 = colors.whiteLight; # Adwaita darker
          # Advanced
          update_check_interval = "0"; # no update check
          auto_reload_config = "0"; # no auto-reload
          clipboard_control = "write-clipboard write-primary read-clipboard read-primary"; # hands off!
          shell_integration = "disabled";
          term = "xterm-kitty";
          # OS specific tweaks
          macos_option_as_alt = if pkgs.stdenv.hostPlatform.isDarwin then "left" else "no";
          macos_quit_when_last_window_closed = "yes"; # quit on close
          linux_display_server = "wayland"; # always wayland
          # Keyboard shortcuts
          clear_all_shortcuts = "yes";
        };
      };
    };
}
