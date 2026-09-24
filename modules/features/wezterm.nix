root: {
  flake.modules.homeManager.wezterm =
    { pkgs, ... }:
    let
      palette = root.config.palettes.adwaita_dark;
    in
    {
      home.packages = [ pkgs.hack-font ];

      programs.wezterm = {
        enable = true;

        # home-manager sources wezterm.sh into the shell by default; tmux owns
        # the terminal here, so the OSC escapes buy nothing
        enableBashIntegration = false;
        enableZshIntegration = false;

        extraConfig = ''
          local wezterm = require "wezterm"
          local act = wezterm.action

          local config = {}

          -- Core behavior
          config.check_for_updates = false
          config.automatically_reload_config = false -- perf: don’t auto-reload on save
          config.quit_when_all_windows_are_closed = true
          config.exit_behavior = "Close"
          config.window_close_confirmation = "NeverPrompt"
          config.mux_enable_ssh_agent = false
          config.alternate_buffer_wheel_scroll_speed = 1
          config.enable_kitty_graphics = false -- no inline images; tmux owns the terminal

          -- UI
          config.enable_tab_bar = false
          config.enable_scroll_bar = false
          config.adjust_window_size_when_changing_font_size = false
          config.hide_mouse_cursor_when_typing = false
          config.audible_bell = "Disabled"
          config.window_padding = { left = "0.5cell", right = "0.5cell", top = "0.25cell", bottom = "0.25cell" }

          -- Cursor
          config.default_cursor_style = "SteadyBlock"
          config.cursor_blink_rate = 0

          -- Input
          config.disable_default_mouse_bindings = true
          config.disable_default_key_bindings = true
          config.disable_default_quick_select_patterns = true
          config.bypass_mouse_reporting_modifiers = "SHIFT" -- bypass app mouse mode

          -- Scrollback
          config.scrollback_lines = 10000

          -- Font
          config.font = wezterm.font "Hack"
          config.font_size = 16.0
          config.font_dirs = { "${pkgs.hack-font}/share/fonts/truetype" } -- CoreText cannot see the HM profile on macOS

          -- Keybinds
          config.keys = {
            { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
            { key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

            { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
            { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
            { key = "0", mods = "CTRL", action = act.ResetFontSize },

            { key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-0.5) },
            { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(0.5) },
          }

          -- Mousebinds
          config.mouse_bindings = {
            { event = { Down = { streak = 1, button = { WheelUp = 1 } } }, mods = "NONE", action = act.ScrollByCurrentEventWheelDelta },
            { event = { Down = { streak = 1, button = { WheelDown = 1 } } }, mods = "NONE", action = act.ScrollByCurrentEventWheelDelta },

            { event = { Down = { streak = 1, button = "Left" } }, mods = "NONE", action = act.SelectTextAtMouseCursor("Cell") },
            { event = { Drag = { streak = 1, button = "Left" } }, mods = "NONE", action = act.ExtendSelectionToMouseCursor("Cell") },
            { event = { Up = { streak = 1, button = "Left" } }, mods = "NONE", action = act.CompleteSelection("PrimarySelection") },

            { event = { Down = { streak = 2, button = "Left" } }, mods = "NONE", action = act.SelectTextAtMouseCursor("Word") },
            { event = { Down = { streak = 3, button = "Left" } }, mods = "NONE", action = act.SelectTextAtMouseCursor("Line") },

            { event = { Down = { streak = 1, button = "Left" } }, mods = "CTRL|SHIFT", action = act.SelectTextAtMouseCursor("Block") },
            { event = { Drag = { streak = 1, button = "Left" } }, mods = "CTRL|SHIFT", action = act.ExtendSelectionToMouseCursor("Block") },
            { event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL|SHIFT", action = act.CompleteSelection("PrimarySelection") },
          }

          -- macOS-only; wezterm parses but ignores these on other platforms.
          config.native_macos_fullscreen_mode = false -- fullscreen is a fast borderless window, not a macOS Space
          config.macos_fullscreen_extend_behind_notch = false -- fullscreen stops at the notch instead of drawing behind it
          config.macos_window_background_blur = 0 -- no blur; only takes effect with window_background_opacity < 1
          config.macos_forward_to_ime_modifier_mask = "SHIFT" -- Shift combos go to the system IME, Ctrl/Alt reach tmux and nvim

          config.color_schemes = {
            ["Adwaita Dark"] = {
              background = "${palette.background}",
              foreground = "${palette.foreground}",
              cursor_bg = "${palette.cursor}",
              cursor_fg = "${palette.cursor_text_color}",
              selection_bg = "${palette.selection_background}",
              selection_fg = "${palette.selection_foreground}",
              ansi = {
                "${palette.color0}",
                "${palette.color1}",
                "${palette.color2}",
                "${palette.color3}",
                "${palette.color4}",
                "${palette.color5}",
                "${palette.color6}",
                "${palette.color7}",
              },
              brights = {
                "${palette.color8}",
                "${palette.color9}",
                "${palette.color10}",
                "${palette.color11}",
                "${palette.color12}",
                "${palette.color13}",
                "${palette.color14}",
                "${palette.color15}",
              },
            },
          }
          config.color_scheme = "Adwaita Dark"

          return config
        '';
      };
    };
}
