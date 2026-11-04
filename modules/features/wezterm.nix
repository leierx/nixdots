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

          -- Core behavior
          config.check_for_updates = false
          config.automatically_reload_config = false -- perf: don’t auto-reload on save
          config.quit_when_all_windows_are_closed = true
          config.exit_behavior = "Close"
          config.window_close_confirmation = "NeverPrompt"
          config.mux_enable_ssh_agent = false
          config.alternate_buffer_wheel_scroll_speed = 1
          config.enable_kitty_graphics = true
          config.enable_kitty_keyboard = true -- modified keys like Shift+Enter for pi/claude; apps opt in

          -- Multiplexer: panes live in wezterm-mux-server (the built-in "unix" domain), so they survive the GUI.
          -- Closing any window detaches the whole domain in that GUI; the next `wezterm` re-attaches.
          -- The server reads this file only at its own start: `pkill -x wezterm-mux-server` (kills its panes) to apply changes.
          config.default_domain = "unix"

          -- UI
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

          -- Cursor
          config.default_cursor_style = "SteadyBlock"
          config.cursor_blink_rate = 0

          -- Input
          config.disable_default_mouse_bindings = true
          config.disable_default_key_bindings = true
          config.disable_default_quick_select_patterns = true
          config.bypass_mouse_reporting_modifiers = "SHIFT" -- bypass app mouse mode

          -- Scrollback
          config.scrollback_lines = 500000

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
            -- alternative for C-b C-b: send a real C-b to the shell (zsh backward-char) instead
            -- { key = "b", mods = "LEADER|CTRL", action = act.SendKey { key = "b", mods = "CTRL" } },
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

          -- Mousebinds
          config.mouse_bindings = {
            { event = { Down = { streak = 1, button = { WheelUp = 1 } } }, mods = "NONE", action = act.ScrollByCurrentEventWheelDelta },
            { event = { Down = { streak = 1, button = { WheelDown = 1 } } }, mods = "NONE", action = act.ScrollByCurrentEventWheelDelta },

            { event = { Down = { streak = 1, button = "Left" } }, mods = "NONE", action = act.SelectTextAtMouseCursor("Cell") },
            { event = { Drag = { streak = 1, button = "Left" } }, mods = "NONE", action = act.ExtendSelectionToMouseCursor("Cell") },
            { event = { Up = { streak = 1, button = "Left" } }, mods = "NONE", action = act.CompleteSelection("PrimarySelection") },

            { event = { Down = { streak = 2, button = "Left" } }, mods = "NONE", action = act.SelectTextAtMouseCursor("Word") },
            { event = { Down = { streak = 3, button = "Left" } }, mods = "NONE", action = act.SelectTextAtMouseCursor("Line") },

            -- Ctrl-click opens the link under the cursor; the Down bind keeps the
            -- press from leaking to apps that track the mouse.
            { event = { Down = { streak = 1, button = "Left" } }, mods = "CTRL", action = act.Nop },
            { event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL", action = act.OpenLinkAtMouseCursor },

            { event = { Down = { streak = 1, button = "Left" } }, mods = "CTRL|SHIFT", action = act.SelectTextAtMouseCursor("Block") },
            { event = { Drag = { streak = 1, button = "Left" } }, mods = "CTRL|SHIFT", action = act.ExtendSelectionToMouseCursor("Block") },
            { event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL|SHIFT", action = act.CompleteSelection("PrimarySelection") },
          }

          -- macOS-only; wezterm parses but ignores these on other platforms.
          config.native_macos_fullscreen_mode = false -- fullscreen is a fast borderless window, not a macOS Space
          config.macos_fullscreen_extend_behind_notch = false -- fullscreen stops at the notch instead of drawing behind it
          config.macos_window_background_blur = 0 -- no blur; only takes effect with window_background_opacity < 1
          config.macos_forward_to_ime_modifier_mask = "SHIFT" -- Shift combos go to the system IME, Ctrl/Alt reach wezterm binds and nvim

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

          -- Check binds with `wezterm show-keys --lua`; see raw key names with
          -- config.debug_key_events = true + `wezterm start` from a terminal.
          --
          -- M8. Panes.
          -- config.inactive_pane_hsb = { hue = 1.0, saturation = 0.9, brightness = 0.8 } -- dim unfocused panes; all 1.0 = no dimming
          -- config.pane_focus_follows_mouse = false
          -- config.unzoom_on_switch_pane = true         -- false = ActivatePaneDirection does nothing while zoomed
          -- config.swallow_mouse_click_on_pane_focus = false -- true = the click that focuses a pane isn't sent to it
          -- config.quick_select_alphabet = "asdfqwerzxcvjklmiuopghtybn" -- also PaneSelect's labels
          -- config.pane_select_font_size = 36
          -- config.pane_select_font = nil               -- default: window_frame.font
          -- config.pane_select_fg_color = nil           -- default 75% grey
          -- config.pane_select_bg_color = nil           -- default black at 50% alpha
          --
          -- M9. Leader and key tables.
          -- config.leader = nil                         -- { key, mods, timeout_milliseconds = 1000 }
          -- config.key_tables = {}                      -- named modes for ActivateKeyTable { name, one_shot = true, timeout_milliseconds, replace_current, until_unknown, prevent_fallback }
          --   copy_mode and search_mode tables are built in; defining either replaces it whole
          --   (`wezterm show-keys --lua --key-table copy_mode` dumps the default to start from).
          --
          -- M10. Startup layouts (tmuxinator-style).
          -- wezterm.on("gui-startup", function(cmd)     -- `wezterm start` only, not `connect`
          --   local tab, pane, window = wezterm.mux.spawn_window(cmd or { workspace = "main" })
          --   pane:split { direction = "Right", size = 0.4 }
          -- end)
          -- wezterm.on("mux-startup", function()        -- runs once when a mux server starts; panes it makes replace the default shell
          --   local tab, pane, window = wezterm.mux.spawn_window { workspace = "nixdots", cwd = wezterm.home_dir .. "/Projects/nixdots" }
          --   wezterm.mux.set_active_workspace("nixdots")
          -- end)
          --
          return config
        '';
      };
    };
}
