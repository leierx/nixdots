{ lib, ... }:
{
  modules.home.wezterm =
    { pkgs, theme, ... }:
    {
      home.packages = [ pkgs.hack-font ];

      programs.wezterm = {
        enable = true;
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
          config.scrollback_lines = 69000

          -- Font
          config.font = wezterm.font "Hack"
          config.font_size = 16.0

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

          -- Colors
          config.colors = {
            foreground = "${theme.colors.fg}",
            background = "${theme.colors.bg1}",

            selection_fg = "none",
            selection_bg = "rgba(255 255 255 / 30%)",

            cursor_bg = "${theme.colors.fg}",
            cursor_fg = "${theme.colors.bg1}",
            cursor_border = "${theme.colors.fg}",

            ansi = {
              "${theme.colors.black}",
              "${theme.colors.red}",
              "${theme.colors.green}",
              "${theme.colors.yellow}",
              "${theme.colors.blue}",
              "${theme.colors.magenta}",
              "${theme.colors.cyan}",
              "${theme.colors.white}",
            },

            brights = {
              "${theme.colors.blackLight}",
              "${theme.colors.redLight}",
              "${theme.colors.greenLight}",
              "${theme.colors.yellowLight}",
              "${theme.colors.blueLight}",
              "${theme.colors.magentaLight}",
              "${theme.colors.cyanLight}",
              "${theme.colors.whiteLight}",
            },
          }

          return config
        '';
      };
    };
}
