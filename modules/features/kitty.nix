root: {
  flake.modules.homeManager.kitty =
    { pkgs, ... }:
    {
      programs.kitty = {
        enable = true;
        themeFile = "adwaita_darker";
        shellIntegration.mode = null; # Keep HM out of my shell rc; kitty setting below wins.
        font = {
          name = "Hack";
          package = pkgs.hack-font;
          size = 16.0;
        };
        keybindings = {
          "ctrl+shift+c" = "copy_to_clipboard";
          "ctrl+shift+v" = "paste_from_clipboard";
          "ctrl+plus" = "change_font_size all +2.0";
          "ctrl+minus" = "change_font_size all -2.0";
          "ctrl+0" = "change_font_size all 0";
        };
        settings = {
          cursor_shape = "block";
          # Scrollback
          scrollback_lines = "10000"; # standard long scrollback
          scrollbar = "never"; # do not use scrollbar
          scrollbar_interactive = "no"; # do not use scrollbar
          # Mouse
          mouse_hide_wait = "0"; # never autohide
          copy_on_select = "yes";
          paste_actions = "no-op"; # hands off!
          clear_all_mouse_actions = "no";
          # Terminal bell
          enable_audio_bell = "no"; # hands off!
          window_alert_on_bell = "no"; # hands off!
          macos_dock_badge_on_bell = "yes";
          # Window layout
          remember_window_size = "no"; # hands off!
          enabled_layouts = "splits"; # better than "all", no "disable"
          draw_minimal_borders = "no";
          confirm_os_window_close = "0"; # no confirm
          # Reverse-video selection, overrides the theme
          selection_foreground = "none";
          selection_background = "none";
          # Advanced
          update_check_interval = "0"; # no update check
          auto_reload_config = "0"; # no auto-reload
          clipboard_control = "write-clipboard write-primary read-clipboard read-primary"; # hands off!
          shell_integration = "disabled";
          term = "xterm-kitty";
          # OS specific tweaks
          macos_option_as_alt = if pkgs.stdenv.hostPlatform.isDarwin then "left" else "no";
          macos_titlebar_color = "background"; # follow the theme, not the OS light/dark appearance
          macos_quit_when_last_window_closed = "yes"; # quit on close
          linux_display_server = "wayland"; # always wayland
          clear_all_shortcuts = "yes";
        };
      };
    };
}
