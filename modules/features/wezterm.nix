{
  flake.modules.homeManager.wezterm =
    { pkgs, ... }:
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
          config.color_scheme = "Colors (base16)"

          -- -------------------------------------------------------------------
          -- Reference: defaults for every other wezterm option.
          -- Each line is commented out: delete it to use wezterm's built-in
          -- default, or remove the leading "-- " to set that value explicitly.
          -- Options already set above are intentionally omitted.
          -- -------------------------------------------------------------------

          -- ===== Core behavior =====
          -- config.switch_to_last_active_tab_when_closing_tab = false -- If set to true, when the active tab is closed, the previously activated tab will be activated
          -- config.prefer_to_spawn_tabs = false -- When true, launching a new wezterm instance will prefer to spawn a new tab into an existing instance. Otherwise, it will spawn a new window
          -- config.exit_behavior_messaging = "Verbose" -- Controls how wezterm indicates the exit status of the spawned process in a pane when it terminates
          -- config.clean_exit_codes = {} -- Extra exit codes treated as clean by exit_behavior; code 0 is always clean
          -- config.detect_password_input = true -- Detect password prompts (PTY local echo off) and suppress echo of secrets
          -- config.show_update_window = false -- Show a window when a new version is found
          -- config.check_for_updates_interval_seconds = 86400 -- Seconds between update checks
          -- config.status_update_interval = 1000 -- Milliseconds between status hook updates
          -- config.default_gui_startup_args = { "start" } -- Arguments used when the GUI is launched with no explicit subcommand

          -- ===== Window =====
          -- config.window_decorations = "TITLE | RESIZE" -- Configures whether the window has a title bar and/or resizable border
          -- config.integrated_title_buttons = { "Hide", "Maximize", "Close" } -- Configures the ordering and set of window management buttons to show when window_decorations = "INTEGRATED_BUTTONS|RESIZE"
          -- config.integrated_title_button_alignment = "Right" -- Configures the alignment of the set of window management buttons when window_decorations = "INTEGRATED_BUTTONS|RESIZE"
          -- config.integrated_title_button_style = "Windows" -- Configures the visual style of the tabbar-integrated titlebar button replacements that are shown when window_decorations = "INTEGRATED_BUTTONS|RESIZE"
          -- config.integrated_title_button_color = "Auto" -- Configures the color of the set of window management buttons when window_decorations = "INTEGRATED_BUTTONS|RESIZE"
          -- config.window_frame = { inactive_titlebar_bg = "#333333", active_titlebar_bg = "#333333", inactive_titlebar_fg = "#cccccc", active_titlebar_fg = "#ffffff", inactive_titlebar_border_bottom = "#2b2042", active_titlebar_border_bottom = "#2b2042", button_fg = "#cccccc", button_bg = "#333333", button_hover_fg = "#ffffff", button_hover_bg = "#1f1f1f", border_left_width = 0, border_right_width = 0, border_top_height = 0, border_bottom_height = 0 } -- Colors and border widths for client-side window decorations (mainly Wayland)
          -- config.window_content_alignment = { horizontal = "Left", vertical = "Top" } -- Alignment of the terminal cells inside the window
          -- config.use_resize_increments = false -- Snap window size to whole cell increments
          -- config.initial_rows = 24 -- Height of a new window in character cells
          -- config.initial_cols = 80 -- Width of a new window in character cells
          -- config.dpi = nil -- DPI to assume; unset uses the system DPI
          -- config.dpi_by_screen = {} -- Per-screen DPI overrides, keyed by screen name
          -- config.native_macos_fullscreen_mode = false -- Use native macOS fullscreen (macOS only)
          -- config.macos_fullscreen_extend_behind_notch = false -- Extend the fullscreen window behind the notch (macOS only)
          -- config.tiling_desktop_environments = { "X11 LG3D", "X11 Qtile", "X11 awesome", "X11 bspwm", "X11 dwm", "X11 i3", "X11 xmonad" } -- Window environments treated as tiling window managers

          -- ===== Tab bar =====
          -- config.use_fancy_tab_bar = true -- When set to true (the default), the tab bar is rendered in a native style with proportional fonts
          -- config.tab_bar_at_bottom = false -- When tab_bar_at_bottom = true, the tab bar will be rendered at the bottom of the window rather than the top of the window
          -- config.mouse_wheel_scrolls_tabs = true -- Scroll wheel over the tab bar switches tabs
          -- config.show_tab_index_in_tab_bar = true -- Prefix each tab title with its index
          -- config.show_tabs_in_tab_bar = true -- When set to true (the default), the tab bar will display the tabs associated with the current window
          -- config.show_new_tab_button_in_tab_bar = true -- Show the new-tab button in the tab bar
          -- config.show_close_tab_button_in_tabs = true -- When set to false, the close-tab button will not be drawn in tabs when the fancy tab bar is in use. Default is true
          -- config.tab_and_split_indices_are_zero_based = false -- If true, show_tab_index_in_tab_bar uses a zero-based index. The default is false and the tab shows a one-based index
          -- config.tab_max_width = 16 -- Specifies the maximum width that a tab can have in the tab bar. Defaults to 16 glyphs in width
          -- config.hide_tab_bar_if_only_one_tab = false -- If true, hide the tab bar if the window only has a single tab
          -- config.tab_bar_style = { new_tab = " + ", new_tab_hover = " + ", window_hide = " . ", window_hide_hover = " . ", window_maximize = " - ", window_maximize_hover = " - ", window_close = " X ", window_close_hover = " X " } -- Glyphs/strings used to draw tab bar elements

          -- ===== Fonts =====
          -- config.line_height = 1.0 -- Scales the computed line height to adjust the spacing between successive rows of text
          -- config.cell_width = 1.0 -- Scales the computed cell width to adjust the spacing between successive cells of text
          -- config.font_rules = {} -- Rules that select a font style based on cell attributes (bold/italic/etc)
          -- config.font_dirs = {} -- Extra directories to search for fonts
          -- config.font_locator = "FontConfig" -- Method used to locate system fonts
          -- config.font_rasterizer = "FreeType" -- Method used to render fonts on screen
          -- config.font_colr_rasterizer = "Harfbuzz" -- Rasterizer used for COLR color fonts
          -- config.font_shaper = "Harfbuzz" -- Method used to map text to glyphs (kerning/ligatures)
          -- config.display_pixel_geometry = "RGB" -- Subpixel anti-aliasing order (RGB or BGR)
          -- config.freetype_load_target = "Normal" -- Hinting/render mode for the freetype rasterizer
          -- config.freetype_render_target = nil -- Rendering mode for freetype; unset follows freetype_load_target
          -- config.freetype_load_flags = nil -- Advanced freetype load flags bitfield
          -- config.freetype_interpreter_version = nil -- Freetype interpreter version (35, 38 or 40)
          -- config.freetype_pcf_long_family_names = false -- Control the freetype PCF no-long-family-names property
          -- config.harfbuzz_features = { "kern", "liga", "clig" } -- OpenType features to enable in harfbuzz shaping
          -- config.allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace" -- How square symbol glyphs may overflow their cell (Never/Always/WhenFollowedBySpace)
          -- config.custom_block_glyphs = true -- Synthesize block/box glyphs instead of using font glyphs
          -- config.anti_alias_custom_block_glyphs = true -- Anti-alias the synthesized block glyphs
          -- config.use_cap_height_to_scale_fallback_fonts = false -- Scale fallback fonts using cap-height metrics
          -- config.warn_about_missing_glyphs = true -- Show a toast when a glyph is missing from the configured fonts
          -- config.sort_fallback_fonts_by_coverage = false -- Order fallback fonts by glyph coverage
          -- config.search_font_dirs_for_fallback = false -- Include font_dirs when searching for fallback fonts
          -- config.cell_widths = nil -- Override the computed cell width for specific characters
          -- config.char_select_font = nil -- Font to use for CharSelect
          -- config.char_select_font_size = 18.0 -- Specifies the size of the font used with CharSelect
          -- config.char_select_fg_color = "#bfbfbf" -- Specifies the text color used by CharSelect
          -- config.char_select_bg_color = "#333333" -- Specifies the background color used by CharSelect

          -- ===== Colors & background =====
          -- config.color_schemes = {} -- Additional named color schemes
          -- config.colors = nil -- Overrides individual palette colors; normally set via color_scheme
          -- config.resolved_palette = nil -- Internal computed palette derived from colors/color_scheme; not a user option, leave it commented
          -- config.color_scheme_dirs = {} -- Extra directories to search for color scheme files
          -- config.bold_brightens_ansi_colors = "BrightAndBold" -- How bold maps to the bright palette range (BrightAndBold shifts indices 0-7 to 8-15)
          -- config.background = {} -- Layered background image/gradient/color composition
          -- config.window_background_image = nil -- Path to a background image
          -- config.window_background_gradient = nil -- Gradient used to generate the window background image
          -- config.window_background_image_hsb = nil -- HSB transform applied to the window background image
          -- config.foreground_text_hsb = { hue = 1.0, saturation = 1.0, brightness = 1.0 } -- HSB transform applied to monochrome foreground text
          -- config.window_background_opacity = 1.0 -- Specifies the alpha value to use when rendering the background of the window
          -- config.inactive_pane_hsb = { hue = 1.0, saturation = 0.9, brightness = 0.8 } -- HSB transform applied to inactive panes
          -- config.text_background_opacity = 1.0 -- Alpha value for explicitly-set text background colors (0.0-1.0)
          -- config.text_min_contrast_ratio = nil -- Minimum contrast ratio for text background colors; nil disables the check
          -- config.macos_window_background_blur = 0 -- Background blur radius (macOS only)
          -- config.kde_window_background_blur = false -- Background blur (KDE Wayland only)
          -- config.win32_system_backdrop = "Auto" -- Window backdrop effect (Windows only)
          -- config.win32_acrylic_accent_color = "#282828" -- Accent color for the Win32 acrylic backdrop (Windows only)

          -- ===== Cursor & blinking =====
          -- config.cursor_thickness = nil -- If specified, overrides the base thickness of the lines used to render the textual cursor glyph
          -- config.underline_thickness = nil -- If specified, overrides the base thickness of underlines
          -- config.underline_position = nil -- If specified, overrides the position of underlines
          -- config.strikethrough_position = nil -- If specified, overrides the position of strikethrough lines
          -- config.cursor_blink_ease_in = "Linear" -- Easing function for the cursor fade-in
          -- config.cursor_blink_ease_out = "Linear" -- Easing function for the cursor fade-out
          -- config.force_reverse_video_cursor = false -- Force the cursor to use reverse video colors
          -- config.reverse_video_cursor_min_contrast = 2.5 -- Minimum contrast ratio for the reverse-video cursor
          -- config.text_blink_rate = 500 -- Blink period for normal blinking text, in ms (0 disables)
          -- config.text_blink_ease_in = "Linear" -- Easing function for blinking-text fade-in
          -- config.text_blink_ease_out = "Linear" -- Easing function for blinking-text fade-out
          -- config.text_blink_rate_rapid = 250 -- Blink period for rapid blinking text, in ms (0 disables)
          -- config.text_blink_rapid_ease_in = "Linear" -- Easing function for rapid blinking-text fade-in
          -- config.text_blink_rapid_ease_out = "Linear" -- Easing function for rapid blinking-text fade-out
          -- config.animation_fps = 10 -- Maximum frame rate for blink and visual-bell easing
          -- config.visual_bell = { fade_in_duration_ms = 0, fade_in_function = "Ease", fade_out_duration_ms = 0, fade_out_function = "Ease", target = "BackgroundColor" } -- Visual bell configuration (fade timings and target)

          -- ===== Input & keys =====
          -- config.key_tables = {} -- Named key tables used for modal key bindings
          -- config.leader = nil -- Leader key used to trigger key tables
          -- config.key_map_preference = "Mapped" -- How keys without an explicit phys:/mapped: prefix are treated
          -- config.enable_kitty_keyboard = false -- When set to true, wezterm will honor kitty keyboard protocol escape sequences that modify the keyboard encoding
          -- config.enable_csi_u_key_encoding = false -- Use CSI-u key encoding for modified keys
          -- config.debug_key_events = false -- Log every key event at INFO level
          -- config.normalize_output_to_unicode_nfc = false -- Normalize terminal output to Unicode NFC
          -- config.send_composed_key_when_left_alt_is_pressed = false -- Send composed (dead-key) characters for Left Alt combinations
          -- config.send_composed_key_when_right_alt_is_pressed = true -- Send composed (dead-key) characters for Right Alt combinations
          -- config.macos_forward_to_ime_modifier_mask = "SHIFT" -- Modifiers forwarded to the macOS IME when use_ime is true (macOS only)
          -- config.treat_left_ctrlalt_as_altgr = false -- Treat Ctrl+Alt as AltGr for layouts that use AltGr
          -- config.swap_backspace_and_delete = false -- If true, the Backspace and Delete keys generate Delete and Backspace keypresses, respectively, rather than their normal keycodes
          -- config.selection_word_boundary = " \t\n{[}]()\"'`" -- Characters that bound a word for mouse selection
          -- config.quick_select_patterns = {} -- Additional regex patterns to match in quick select mode
          -- config.quick_select_alphabet = "asdfqwerzxcvjklmiuopghtybn" -- Specify the alphabet used to produce labels for the items matched in quick select mode
          -- config.quick_select_remove_styling = false -- When set to true, all color and styling is removed from the pane prior to performing matching and highlighting any matching text in quick select mode
          -- config.launcher_alphabet = "1234567890abcdefghilmnopqrstuvwxyz" -- Characters used to label launcher menu entries
          -- config.enable_kitty_graphics = true -- Enable the Kitty graphics protocol (inline images)
          -- config.enq_answerback = "" -- String returned in reply to an ENQ (answerback) query
          -- config.allow_win32_input_mode = true -- Allow ConPTY to switch the keyboard encoding (Windows only)
          -- config.use_dead_keys = true -- Honor dead keys for composing accented characters
          -- config.xim_im_name = nil -- XIM server name for the X11 IME
          -- config.ime_preedit_rendering = "Builtin" -- Who renders IME preedit text
          -- config.use_ime = true -- Use the system input method editor

          -- ===== Mouse =====
          -- config.swallow_mouse_click_on_pane_focus = false -- Ignore the click that focuses a pane
          -- config.swallow_mouse_click_on_window_focus = false -- Ignore the click that focuses the window
          -- config.pane_focus_follows_mouse = false -- Focus the pane under the mouse pointer
          -- config.quote_dropped_files = "SpacesOnly" -- Quoting applied to file paths dropped into the terminal

          -- ===== Scrollback & panes =====
          -- config.min_scroll_bar_height = "0.5cell" -- Minimum height of the scroll bar thumb
          -- config.scroll_to_bottom_on_input = true -- Scroll to the bottom when input is sent to a pane
          -- config.unzoom_on_switch_pane = true -- Unzoom a pane when switching to another pane

          -- ===== Multiplexer & domains =====
          -- config.default_prog = nil -- Program to run instead of the user shell when none is given
          -- config.default_cwd = nil -- Default working directory when none is given
          -- config.set_environment_variables = {} -- Environment variables to set in locally spawned commands
          -- config.default_domain = "local" -- Default multiplexing domain for the GUI
          -- config.default_mux_server_domain = "local" -- Default multiplexing domain for the standalone mux server
          -- config.default_workspace = "default" -- Name of the default workspace
          -- config.unix_domains = {} -- Multiplexer domains reached over a unix socket
          -- config.ssh_domains = nil -- SSH multiplexing domains
          -- config.ssh_backend = "LibSsh" -- SSH backend for the integrated client
          -- config.tls_servers = {} -- TLS endpoints the mux server listens on
          -- config.tls_clients = {} -- TLS domains the client can connect to
          -- config.wsl_domains = nil -- WSL domains (Windows only); nil auto-detects them
          -- config.exec_domains = {} -- User-defined multiplexer domains that launch a command
          -- config.serial_ports = {} -- Serial port domains you use regularly
          -- config.daemon_options = {} -- pid_file/stdout/stderr paths used by the mux daemon
          -- config.default_ssh_auth_sock = nil -- Override SSH_AUTH_SOCK for the multiplexer
          -- config.mux_env_remove = { "SSH_AUTH_SOCK", "SSH_CLIENT", "SSH_CONNECTION" } -- Environment variables removed in the mux server
          -- config.mux_output_parser_buffer_size = 131072 -- Buffer size used by the mux output parser, in bytes
          -- config.mux_output_parser_coalesce_delay_ms = 3 -- Delay in ms to coalesce mux output before parsing
          -- config.ratelimit_mux_line_prefetches_per_second = 50 -- Rate limit for speculative line prefetches from the mux server

          -- ===== Rendering & performance =====
          -- config.front_end = "OpenGL" -- Rendering front end (OpenGL, WebGpu or Software)
          -- config.webgpu_power_preference = "LowPower" -- GPU power preference when using the WebGpu front end
          -- config.webgpu_force_fallback_adapter = false -- Force a software (CPU) WebGpu adapter
          -- config.webgpu_preferred_adapter = nil -- Preferred WebGpu adapter
          -- config.prefer_egl = true -- Whether to prefer EGL over other GL implementations
          -- config.enable_wayland = true -- Prefer a Wayland connection over X11
          -- config.enable_zwlr_output_manager = false -- Use the wlr-output-management protocol for output info (Wayland)
          -- config.max_fps = 60 -- Maximum frames per second wezterm will draw
          -- config.shape_cache_size = 1024 -- Number of shaped runs kept in the shaping cache
          -- config.line_state_cache_size = 1024 -- Number of line states kept in the rendering cache
          -- config.line_quad_cache_size = 1024 -- Number of line quads kept in the rendering cache
          -- config.line_to_ele_shape_cache_size = 1024 -- Number of line-to-element shape entries kept in the cache
          -- config.glyph_cache_image_cache_size = 256 -- Number of glyph images kept in the glyph cache
          -- config.experimental_pixel_positioning = false -- Enable experimental sub-cell pixel positioning
          -- config.periodic_stat_logging = 0 -- Log statistics every N seconds (0 disables)

          -- ===== Overlays =====
          -- config.command_palette_font = nil -- Font to use for ActivateCommandPalette
          -- config.command_palette_font_size = 14.0 -- Specifies the size of the font used with ActivateCommandPalette
          -- config.command_palette_rows = nil -- Specifies the number of rows displayed by the command palette
          -- config.command_palette_fg_color = "#bfbfbf" -- Specifies the text color used by ActivateCommandPalette
          -- config.command_palette_bg_color = "#333333" -- Specifies the background color used by ActivateCommandPalette
          -- config.pane_select_font = nil -- Font to use for PaneSelect
          -- config.pane_select_font_size = 36.0 -- Font size used by the PaneSelect overlay
          -- config.pane_select_fg_color = "#bfbfbf" -- Foreground color used by the PaneSelect overlay
          -- config.pane_select_bg_color = "rgba(0, 0, 0, 0.5)" -- Background color used by the PaneSelect overlay
          -- config.launch_menu = {} -- Entries for the launcher menu
          -- config.ui_key_cap_rendering = "UnixLong" -- Style used to render modifier key caps in the UI
          -- config.palette_max_key_assigments_for_action = 1 -- Maximum key assignments listed per action in the command palette (name is misspelled upstream)

          -- ===== Misc & platform =====
          -- config.term = "xterm-256color" -- Value to set the TERM environment variable to
          -- config.ulimit_nofile = 2048 -- Minimum desirable RLIMIT_NOFILE soft limit (Unix)
          -- config.ulimit_nproc = 2048 -- Minimum desirable RLIMIT_NPROC soft limit (Unix)
          -- config.ignore_svg_fonts = false -- Ignore SVG-in-OpenType font glyphs
          -- config.bidi_enabled = false -- Enable bidirectional (RTL/LTR) text shaping
          -- config.bidi_direction = "LeftToRight" -- Default paragraph direction for bidi text
          -- config.treat_east_asian_ambiguous_width_as_wide = false -- Treat East Asian ambiguous-width characters as wide
          -- config.unicode_version = 9 -- Unicode version used for width/presentation decisions
          -- config.allow_download_protocols = true -- Allow terminal download protocols to write files
          -- config.notification_handling = "AlwaysShow" -- How toast notifications are shown
          -- config.use_box_model_render = false -- Render box-drawing characters with the box model
          -- config.skip_close_confirmation_for_processes_named = { "bash", "sh", "zsh", "fish", "tmux", "nu", "nu.exe", "cmd.exe", "pwsh.exe", "powershell.exe" } -- Processes considered stateless and safe to close without confirming
          -- config.hyperlink_rules = wezterm.default_hyperlink_rules() -- Rules mapping terminal text to clickable links
          -- config.xcursor_theme = nil -- X11 cursor theme name; unset uses the system theme
          -- config.xcursor_size = nil -- X11 cursor size in pixels; unset uses the system size
          -- config.enable_title_reporting = false -- Allow applications to read the window title via escape sequences
          -- config.enable_checksum_rectangular_area = false -- Allow DECRQCRA checksum requests (disabled by default for security)
          -- config.log_unknown_escape_sequences = false -- Log warnings for escape sequences wezterm does not understand
          -- config.canonicalize_pasted_newlines = nil -- How newlines in pasted text are normalized

          return config
        '';
      };
    };
}
