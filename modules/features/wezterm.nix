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
        enableBashIntegration = false;
        enableZshIntegration = false;
        extraConfig = ''
          local wezterm = require "wezterm"
          local act = wezterm.action

          local config = {}

          config.check_for_updates = false
          config.automatically_reload_config = false -- perf
          config.quit_when_all_windows_are_closed = true
          config.exit_behavior = "Close"
          config.window_close_confirmation = "NeverPrompt"
          config.mux_enable_ssh_agent = false
          config.alternate_buffer_wheel_scroll_speed = 1
          config.enable_kitty_graphics = true
          config.enable_kitty_keyboard = true -- modified keys like Shift+Enter for pi/claude; apps opt in

          -- panes live in wezterm-mux-server so they survive the GUI; it reads this file only at its start,
          -- so `pkill -x wezterm-mux-server` (killing its panes) applies changes
          config.default_domain = "unix"

          config.enable_tab_bar = true
          config.hide_tab_bar_if_only_one_tab = true
          config.show_new_tab_button_in_tab_bar = false
          config.window_frame = {
            active_titlebar_bg = "${palette.background}",
            inactive_titlebar_bg = "${palette.background}",
          }
          config.enable_scroll_bar = false
          config.adjust_window_size_when_changing_font_size = false
          config.hide_mouse_cursor_when_typing = false
          config.audible_bell = "Disabled"
          config.window_padding = { left = "0.5cell", right = "0.5cell", top = "0.25cell", bottom = "0.25cell" }

          config.default_cursor_style = "SteadyBlock"
          config.cursor_blink_rate = 0

          config.disable_default_mouse_bindings = true
          config.disable_default_key_bindings = true
          config.disable_default_quick_select_patterns = true
          config.bypass_mouse_reporting_modifiers = "SHIFT"

          config.scrollback_lines = 500000

          config.font = wezterm.font "Hack"
          config.font_size = 16.0
          config.font_dirs = { "${pkgs.hack-font}/share/fonts/truetype" } -- CoreText cannot see the HM profile on macOS

          config.keys = {
            { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
            { key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

            { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
            { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
            { key = "0", mods = "CTRL", action = act.ResetFontSize },

            { key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-0.5) },
            { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(0.5) },
          }

          config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 }
          local leader_keys = {
            { key = "v", mods = "LEADER", action = act.SplitPane { direction = "Right" } },
            { key = "s", mods = "LEADER", action = act.SplitPane { direction = "Down" } },
            { key = "c", mods = "LEADER", action = act.SpawnTab "CurrentPaneDomain" },
            { key = "h", mods = "LEADER", action = act.ActivatePaneDirection "Left" },
            { key = "j", mods = "LEADER", action = act.ActivatePaneDirection "Down" },
            { key = "k", mods = "LEADER", action = act.ActivatePaneDirection "Up" },
            { key = "l", mods = "LEADER", action = act.ActivatePaneDirection "Right" },
            { key = "m", mods = "LEADER", action = act.TogglePaneZoomState },
            { key = "x", mods = "LEADER", action = act.CloseCurrentPane { confirm = true } },
            { key = "d", mods = "LEADER", action = act.DetachDomain "CurrentPaneDomain" },
            { key = "t", mods = "LEADER", action = act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES|TABS|DOMAINS" } },
            { key = ":", mods = "LEADER|SHIFT", action = act.ActivateCommandPalette },
            { key = "r", mods = "LEADER", action = act.ActivateKeyTable { name = "resize", one_shot = false } },
            { key = "p", mods = "LEADER", action = act.ActivateCopyMode },
            { key = "<", mods = "LEADER", action = act.MoveTabRelative(-1) },
            { key = ">", mods = "LEADER|SHIFT", action = act.MoveTabRelative(1) },
            { key = "b", mods = "LEADER|CTRL", action = act.ActivateTabRelative(1) },
            -- "/" is shifted on Nordic layouts and unshifted on US, so bind both
            { key = "/", mods = "LEADER", action = act.Search { CaseInSensitiveString = "" } },
            { key = "/", mods = "LEADER|SHIFT", action = act.Search { CaseInSensitiveString = "" } },
          }
          for i = 1, 9 do
            table.insert(leader_keys, { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - 1) })
          end
          for _, k in ipairs(leader_keys) do table.insert(config.keys, k) end
          wezterm.on("update-status", function(window, pane)
            local mode = window:leader_is_active() and "LEADER" or window:active_key_table() or ""
            window:set_right_status(mode .. "  " .. window:active_workspace() .. " ")
          end)
          config.key_tables = {
            resize = {
              { key = "h", action = act.AdjustPaneSize { "Left", 5 } },
              { key = "j", action = act.AdjustPaneSize { "Down", 5 } },
              { key = "k", action = act.AdjustPaneSize { "Up", 5 } },
              { key = "l", action = act.AdjustPaneSize { "Right", 5 } },
              { key = "Escape", action = "PopKeyTable" },
              { key = "Enter", action = "PopKeyTable" },
            },
          }

          config.mouse_bindings = {
            { event = { Down = { streak = 1, button = { WheelUp = 1 } } }, mods = "NONE", action = act.ScrollByCurrentEventWheelDelta },
            { event = { Down = { streak = 1, button = { WheelDown = 1 } } }, mods = "NONE", action = act.ScrollByCurrentEventWheelDelta },

            { event = { Down = { streak = 1, button = "Left" } }, mods = "NONE", action = act.SelectTextAtMouseCursor("Cell") },
            { event = { Drag = { streak = 1, button = "Left" } }, mods = "NONE", action = act.ExtendSelectionToMouseCursor("Cell") },
            { event = { Up = { streak = 1, button = "Left" } }, mods = "NONE", action = act.CompleteSelection("PrimarySelection") },

            { event = { Down = { streak = 2, button = "Left" } }, mods = "NONE", action = act.SelectTextAtMouseCursor("Word") },
            { event = { Down = { streak = 3, button = "Left" } }, mods = "NONE", action = act.SelectTextAtMouseCursor("Line") },

            -- keeps the press from leaking to apps that track the mouse
            { event = { Down = { streak = 1, button = "Left" } }, mods = "CTRL", action = act.Nop },
            { event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL", action = act.OpenLinkAtMouseCursor },

            { event = { Down = { streak = 1, button = "Left" } }, mods = "CTRL|SHIFT", action = act.SelectTextAtMouseCursor("Block") },
            { event = { Drag = { streak = 1, button = "Left" } }, mods = "CTRL|SHIFT", action = act.ExtendSelectionToMouseCursor("Block") },
            { event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL|SHIFT", action = act.CompleteSelection("PrimarySelection") },
          }

          -- macOS-only; ignored elsewhere
          config.native_macos_fullscreen_mode = false
          config.macos_fullscreen_extend_behind_notch = false
          config.macos_window_background_blur = 0
          config.macos_forward_to_ime_modifier_mask = "SHIFT" -- Ctrl/Alt combos reach wezterm and nvim, not the IME

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
              split = "${palette.color8}",
              tab_bar = {
                inactive_tab_edge = "${palette.color8}",
                active_tab = { bg_color = "${palette.color8}", fg_color = "${palette.foreground}" },
                inactive_tab = { bg_color = "${palette.background}", fg_color = "${palette.color7}" },
                inactive_tab_hover = { bg_color = "${palette.color0}", fg_color = "${palette.foreground}" },
                new_tab = { bg_color = "${palette.background}", fg_color = "${palette.color7}" },
                new_tab_hover = { bg_color = "${palette.color0}", fg_color = "${palette.foreground}" },
              },
            },
          }
          config.color_scheme = "Adwaita Dark"

          return config
        '';
      };
    };
}
