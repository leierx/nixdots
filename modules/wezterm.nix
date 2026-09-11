{
  flake.modules.homeManager.wezterm =
    { pkgs, ... }:
    let
      colors = {
        fg = "#f1f1f1";
        bg1 = "#1C1C1C";
        black = "#1e1e1e";
        blackLight = "#323232";
        blue = "#0E66D0";
        blueLight = "#0875F6";
        cyan = "#4BB0E3";
        cyanLight = "#4FC0F7";
        green = "#2BBF3E";
        greenLight = "#2DD042";
        magenta = "#9C48CC";
        magentaLight = "#B24FEA";
        red = "#F13A31";
        redLight = "#FE3C33";
        white = "#F1F1F1";
        whiteLight = "#FEFEFE";
        yellow = "#F1C50F";
        yellowLight = "#FECF0F";
      };
    in
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
            foreground = "${colors.fg}",
            background = "${colors.bg1}",

            selection_fg = "none",
            selection_bg = "rgba(255 255 255 / 30%)",

            cursor_bg = "${colors.fg}",
            cursor_fg = "${colors.bg1}",
            cursor_border = "${colors.fg}",

            ansi = {
              "${colors.black}",
              "${colors.red}",
              "${colors.green}",
              "${colors.yellow}",
              "${colors.blue}",
              "${colors.magenta}",
              "${colors.cyan}",
              "${colors.white}",
            },

            brights = {
              "${colors.blackLight}",
              "${colors.redLight}",
              "${colors.greenLight}",
              "${colors.yellowLight}",
              "${colors.blueLight}",
              "${colors.magentaLight}",
              "${colors.cyanLight}",
              "${colors.whiteLight}",
            },
          }

          return config
        '';
      };
    };
}
