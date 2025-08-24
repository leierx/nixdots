{ config, pkgs, lib, ... }:
let
  theme = config.dots.theme;
  cfg = config.dots.gui.apps.wezterm;
in
{
  options.dots.gui.apps.wezterm.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.hack-font ];

    home-manager.sharedModules = [
      ({
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
              foreground = "${theme.fg}", -- Foreground (default text)
              background = "${theme.bg1}", -- Background

              selection_fg = "none",
              selection_bg = "rgba(255 255 255 / 30%)",
              -- waiting for https://github.com/wezterm/wezterm/pull/4093

              cursor_bg = "${theme.fg}",
              cursor_fg = "${theme.bg1}",
              cursor_border = "${theme.fg}",

              ansi = {
                "${theme.black}", -- Black
                "${theme.red}", -- Red
                "${theme.green}", -- Green
                "${theme.yellow}", -- Yellow
                "${theme.blue}", -- Blue
                "${theme.magenta}", -- Magenta
                "${theme.cyan}", -- Cyan
                "${theme.white}", -- White
              },

              brights = {
                "${theme.blackLight}", -- Bright Black (Gray)
                "${theme.redLight}", -- Bright Red
                "${theme.greenLight}", -- Bright Green
                "${theme.yellowLight}", -- Bright Yellow
                "${theme.blueLight}", -- Bright Blue
                "${theme.magentaLight}", -- Bright Magenta
                "${theme.cyanLight}", -- Bright Cyan
                "${theme.whiteLight}", -- Bright White
              },
            }

            return config
          '';
        };
      })
    ];
  };
}
