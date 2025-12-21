{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.programs.wezterm;
in
{
  options.nixdots.programs.wezterm = {
    enable = lib.mkEnableOption "Enable wezterm";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${config.nixdots.core.primaryUser.username} = {
      # dependency
      home.packages = [ pkgs.hack-font ];

      # config
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
          config.window_padding = { left = "0.5cell", right = "0.5cell", top  = "0.25cell", bottom = "0.25cell" }

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
            -- Clipboard copy/paste
            { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
            { key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

            -- Font size
            { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
            { key = "+", mods = "CTRL", action = act.IncreaseFontSize }, -- '=' is '+' without Shift
            { key = "0", mods = "CTRL", action = act.ResetFontSize },

            -- Scrollback half-page
            { key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-0.5) },
            { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(0.5) },
          }

          -- Mousebinds
          config.mouse_bindings = {
            -- Wheel scroll (since defaults are off, wire them back to viewport scrolling)
            { event = { Down = { streak = 1, button = { WheelUp = 1 }}}, mods = "NONE", action = act.ScrollByCurrentEventWheelDelta },
            { event = { Down = { streak = 1, button = { WheelDown = 1 }}}, mods = "NONE", action = act.ScrollByCurrentEventWheelDelta },

            -- Selection behavior (begin/extend/complete)
            { event = { Down = { streak = 1, button = "Left" }}, mods = "NONE", action = act.SelectTextAtMouseCursor("Cell") }, -- select-begin (cell)
            { event = { Drag = { streak = 1, button = "Left" }}, mods = "NONE", action = act.ExtendSelectionToMouseCursor("Cell") }, -- drag to extend
            { event = { Up = { streak = 1, button = "Left" }}, mods = "NONE", action = act.CompleteSelection("PrimarySelection") }, -- finish; copy to PRIMARY

            -- Word/line selection:
            { event = { Down = { streak = 2, button = "Left" }}, mods = "NONE", action = act.SelectTextAtMouseCursor("Word") }, -- double: word
            { event = { Down = { streak = 3, button = "Left" }}, mods = "NONE", action = act.SelectTextAtMouseCursor("Line") }, -- triple: line

            -- Block selection: Ctrl+Shift+Left begin block select
            { event = { Down = { streak = 1, button = "Left" }}, mods = "CTRL|SHIFT", action = act.SelectTextAtMouseCursor("Block") },
            { event = { Drag = { streak = 1, button = "Left" }}, mods = "CTRL|SHIFT", action = act.ExtendSelectionToMouseCursor("Block") },
            { event = { Up = { streak = 1, button = "Left" }}, mods = "CTRL|SHIFT", action = act.CompleteSelection("PrimarySelection") },
          }

          -- Colors
          config.colors = {
            foreground = "#f1f1f1",
            background = "#1C1C1C",

            selection_fg = "none",
            selection_bg = "rgba(255 255 255 / 30%)",

            cursor_bg = "#f1f1f1",
            cursor_fg = "#1C1C1C",
            cursor_border = "#f1f1f1",

            ansi = {
              "#1e1e1e",
              "#F13A31",
              "#2BBF3E",
              "#F1C50F",
              "#0E66D0",
              "#9C48CC",
              "#4BB0E3",
              "#F1F1F1",
            },

            brights = {
              "#323232",
              "#FE3C33",
              "#2DD042",
              "#FECF0F",
              "#0875F6",
              "#B24FEA",
              "#4FC0F7",
              "#FEFEFE",
            },
          }

          return config
        '';
      };
    };
  };
}
