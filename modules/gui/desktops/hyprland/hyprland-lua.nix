{ config, inputs, ... }:
let
  outerConfig = config;
in
{
  modules.nixos.hyprland =
    { pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        xwayland.enable = true;
      };

      nix.settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      };

      services.gvfs.enable = true;
      services.gnome.sushi.enable = true;
      environment.systemPackages = [ pkgs.nautilus ];

      home-manager.sharedModules = [ outerConfig.modules.homeManager.hyprland ];
    };

  modules.homeManager.hyprland =
    {
      pkgs,
      osConfig,
      lib,
      ...
    }:
    {
      imports = [
        outerConfig.modules.homeManager.wezterm
        outerConfig.modules.homeManager.rofi
      ];

      home.packages = [ pkgs.wl-clipboard ];

      # wayland.windowManager.hyprland = {
      #   enable = true;
      #   xwayland.enable = true;
      #   package = null;
      #   portalPackage = null;
      #   systemd.variables = [ "--all" ];
      #   settings = {
      #     "$mod" = "SUPER";
      #     "$terminal" = "wezterm";
      #     "$applicationLauncher" = "rofi -modes drun -show drun";
      #     "$screenshot" = "${lib.getExe pkgs.hyprshot} --mode region --freeze --silent --clipboard-only";
      #     # autostart
      #     exec-once = lib.optional osConfig.networking.networkmanager.enable "${lib.getExe pkgs.networkmanagerapplet}";
      #   };
      # };

      wayland.windowManager.hyprland = {
        enable = true;
        package = osConfig.programs.hyprland.package;
        portalPackage = osConfig.programs.hyprland.portalPackage;
        plugins = [
          inputs.hyprsplit.packages.${pkgs.stdenv.hostPlatform.system}.hyprsplit
        ];
        settings = {
          # ── general ──
          general = {
            border_size = 2;
            gaps_in = 10;
            gaps_out = 15;
            float_gaps = 0;
            gaps_workspaces = 0;
            col = {
              inactive_border = "rgb(595959)";
              active_border = {
                colors = [
                  "rgb(2bbf3e)"
                  "rgb(2bbf3e)"
                  "rgb(2bbf3e)"
                  "rgb(0e66d0)"
                  "rgb(0e66d0)"
                  "rgb(0e66d0)"
                ];
                angle = 30;
              };
              nogroup_border = "0xffffaaff";
              nogroup_border_active = "0xffff00ff";
            };
            # which layout to use. [dwindle/master]
            layout = "dwindle";
            # if true, will not fall back to the next available window when moving focus in a direction where no window was found
            no_focus_fallback = false;
            # enables resizing windows by clicking and dragging on borders and gaps
            resize_on_border = false;
            # extends the area around the border where you can click and drag on, only used when general:resize_on_border is on.
            # (range: [0, 100])
            extend_border_grab_area = 15;
            # show a cursor icon when hovering over borders, only used when general:resize_on_border is on.
            hover_icon_on_border = true;
            # master switch for allowing tearing to occur.
            allow_tearing = false;
            # force floating windows to use a specific corner when being resized (1-4 going clockwise from top left, 0 to disable)
            # (range: [0, 4])
            resize_corner = 0;

            # ── general:snap ──
            snap = {
              # enable snapping for floating windows
              enabled = false;
              # minimum gap in pixels between windows before snapping
              # (range: [0, 100])
              window_gap = 10;
              # minimum gap in pixels between window and monitor edges before snapping
              # (range: [0, 100])
              monitor_gap = 10;
              # if true, windows snap such that only one border's worth of space is between them
              border_overlap = false;
              # if true, snapping will respect gaps between windows
              respect_gaps = false;
            };
            # if true, parent windows of modals will not be interactive.
            modal_parent_blocking = true;
            # overrides the system locale
            locale = "";
          };

          # ── decoration ──
          decoration = {
            # rounded corners' radius (in layout px)
            # (range: [0, 20])
            rounding = 0;
            # rounding power of corners (2 is a circle)
            # (range: [2, 10])
            rounding_power = 2;
            # opacity of active windows.
            # (range: [0, 1])
            active_opacity = 1;
            # opacity of inactive windows.
            # (range: [0, 1])
            inactive_opacity = 1;
            # opacity of fullscreen windows.
            # (range: [0, 1])
            fullscreen_opacity = 1;

            # ── decoration:shadow ──
            shadow = {
              # enable drop shadows on windows
              enabled = true;
              # Shadow range (size) in layout px
              # (range: [0, 100])
              range = 4;
              # in what power to render the falloff (more power, the faster the falloff)
              # (range: [1, 4])
              render_power = 3;
              # whether the shadow should be sharp or not.
              sharp = false;
              # shadow's color. Alpha dictates shadow's opacity.
              color = "0xee1a1a1a"; # 0xAARRGGBB
              # inactive shadow color. (if not set, will fall back to col.shadow)
              color_inactive = -1; # sentinel: inherit from related color
              # shadow's rendering offset.
              # (vec2 range: -250, -250, 250, 250)
              offset = "0 0";
              # shadow's scale.
              # (range: [0, 1])
              scale = 1;
            };

            # ── decoration:glow ──
            glow = {
              # enable inner glow on windows
              enabled = false;
              # glow range (size) in layout px
              # (range: [0, 100])
              range = 10;
              # in what power to render the falloff (more power, the faster the falloff)
              # (range: [1, 4])
              render_power = 3;
              # glow's color. Alpha dictates glow's opacity.
              color = "0xee33ccff"; # 0xAARRGGBB
              # inactive glow color. (if not set, will fall back to decoration:glow:color)
              color_inactive = "0x0033ccff"; # 0xAARRGGBB
            };
            # enables dimming of parents of modal windows
            dim_modal = true;
            # enables dimming of inactive windows
            dim_inactive = false;
            # how much inactive windows should be dimmed
            # (range: [0, 1])
            dim_strength = 0.5;
            # how much to dim the rest of the screen by when a special workspace is open.
            # (range: [0, 1])
            dim_special = 0.2;
            # how much the dimaround window rule should dim by.
            # (range: [0, 1])
            dim_around = 0.4;
            # a path to a custom shader to be applied at the end of rendering.
            screen_shader = "";
            # whether the border should be treated as a part of the window.
            border_part_of_window = true;

            # ── decoration:blur ──
            blur = {
              # enable kawase window background blur
              enabled = true;
              # blur size (distance)
              # (range: [0, 100])
              size = 8;
              # the amount of passes to perform
              # (range: [0, 10])
              passes = 1;
              # make the blur layer ignore the opacity of the window
              ignore_opacity = true;
              # whether to enable further optimizations to the blur.
              new_optimizations = true;
              # if enabled, floating windows will ignore tiled windows in their blur.
              xray = false;
              # how much noise to apply.
              # (range: [0, 1])
              noise = 0.0117;
              # contrast modulation for blur.
              # (range: [0, 2])
              contrast = 0.8916;
              # brightness modulation for blur.
              # (range: [0, 2])
              brightness = 1;
              # Increase saturation of blurred colors.
              # (range: [0, 1])
              vibrancy = 0.1696;
              # How strong the effect of vibrancy is on dark areas.
              # (range: [0, 1])
              vibrancy_darkness = 0;
              # whether to blur behind the special workspace (note: expensive)
              special = false;
              # whether to blur popups (e.g. right-click menus)
              popups = false;
              # works like ignorealpha in layer rules. If pixel opacity is below set value, will not blur.
              # (range: [0, 1])
              popups_ignorealpha = 0.2;
              # whether to blur input methods (e.g. fcitx5)
              input_methods = false;
              # works like ignorealpha in layer rules. If pixel opacity is below set value, will not blur.
              # (range: [0, 1])
              input_methods_ignorealpha = 0.2;
            };
          };

          # ── animations ──
          animations = {
            # enable animations
            enabled = true;
            # changes the direction of slide animations between the first and last workspaces
            workspace_wraparound = false;
          };

          # ── input ──
          input = {
            # Appropriate XKB keymap parameter.
            kb_model = "";
            # Appropriate XKB keymap parameter
            kb_layout = "us";
            # Appropriate XKB keymap parameter
            kb_variant = "";
            # Appropriate XKB keymap parameter
            kb_options = "";
            # Appropriate XKB keymap parameter
            kb_rules = "";
            # Appropriate XKB keymap file
            kb_file = "";
            # Engage numlock by default.
            numlock_by_default = false;
            # Determines how keybinds act when multiple layouts are used.
            resolve_binds_by_sym = false;
            # The repeat rate for held-down keys, in repeats per second.
            # (range: [0, 200])
            repeat_rate = 25;
            # Delay before a held-down key is repeated, in milliseconds.
            # (range: [0, 2000])
            repeat_delay = 600;
            # Sets the mouse input sensitivity. Value is clamped to the range -1.0 to 1.0.
            # (range: [-1, 1])
            sensitivity = 0;
            # Sets the cursor acceleration profile. [adaptive/flat/custom]
            # (choices: adaptive, flat, custom)
            accel_profile = "";
            # Force no cursor acceleration.
            force_no_accel = false;
            # Sets the rotation of a device in degrees clockwise. Value is clamped to the range 0 to 359.
            # (range: [0, 359])
            rotation = 0;
            # Switches RMB and LMB
            left_handed = false;
            # Sets the scroll acceleration profile, when accel_profile is set to custom.
            scroll_points = "";
            # Sets the scroll method. [2fg/edge/on_button_down/no_scroll]
            # (choices: 2fg, edge, on_button_down, no_scroll)
            scroll_method = "";
            # Sets the scroll button. 0 means default.
            # (range: [0, 300])
            scroll_button = 0;
            # If the scroll button lock is enabled, the button does not need to be held down.
            scroll_button_lock = false;
            # Multiplier added to scroll movement for external mice.
            # (range: [0, 2])
            scroll_factor = 1;
            # Inverts scrolling direction.
            natural_scroll = false;
            # Specify if and how cursor movement should affect window focus.
            # (range: [0, 3])
            follow_mouse = 1;
            # The smallest distance in logical pixels the mouse needs to travel for the window under it to get focused.
            follow_mouse_threshold = 0;
            # Controls the window focus behavior when a window is closed.
            # (range: [0, 2])
            focus_on_close = 0;
            # if disabled, mouse focus won't switch to the hovered window unless the mouse crosses a window boundary when follow_mouse=1.
            mouse_refocus = true;
            # If enabled (1 or 2), focus will change to the window under the cursor when changing from tiled-to-floating and vice versa. If 2, focus will also follow mouse on float-to-float switches.
            # (range: [0, 2])
            float_switch_override_focus = 1;
            # if enabled, having only floating windows in the special workspace will not block focusing windows in the regular workspace.
            special_fallthrough = false;
            # How to handle axis events around a focused window.
            # (range: [0, 3])
            off_window_axis_events = 1;
            # Emulates discrete scrolling from high resolution scrolling events.
            # (range: [0, 2])
            emulate_discrete_scroll = 1;
            # Shrinks the inactive window hitboxes used for focus detection by the specified number of pixels. This creates a dead zone in gaps between windows where moving the cursor will not change focus. Works only with follow_mouse = 1.
            # (range: [0, 300])
            follow_mouse_shrink = 0;

            # ── input:touchpad ──
            touchpad = {
              # Disable the touchpad while typing.
              disable_while_typing = true;
              # Inverts scrolling direction.
              natural_scroll = false;
              # Multiplier applied to the amount of scroll movement.
              # (range: [0, 2])
              scroll_factor = 1;
              # Sending LMB and RMB simultaneously will be interpreted as a middle click.
              middle_button_emulation = false;
              # Sets the tap button mapping for touchpad button emulation. [lrm/lmr]
              # (choices: lrm, lmr)
              tap_button_map = "";
              # Button presses with 1, 2, or 3 fingers will be mapped to LMB, RMB, and MMB respectively.
              clickfinger_behavior = false;
              # Tapping on the touchpad with 1, 2, or 3 fingers will send LMB, RMB, and MMB respectively.
              tap-to-click = true;
              # When enabled, lifting the finger off while dragging will not drop the dragged item.
              # (range: [0, 2])
              drag_lock = 0;
              # Sets the tap and drag mode for the touchpad
              tap-and-drag = true;
              # Inverts the horizontal movement of the touchpad
              flip_x = false;
              # Inverts the vertical movement of the touchpad
              flip_y = false;
              # Whether to use 3 or 4 finger drag.
              # (range: [0, 2])
              drag_3fg = 0;
            };

            # ── input:touchdevice ──
            touchdevice = {
              # Transform the input from touchdevices.
              # (range: [0, 6])
              transform = 0;
              # The monitor to bind touch devices.
              output = "[[Auto]]";
              # Whether input is enabled for touch devices.
              enabled = true;
            };

            # ── input:virtualkeyboard ──
            virtualkeyboard = {
              # Unify key down states and modifier states with other keyboards.
              # (range: [0, 2])
              share_states = 2;
              # Release all pressed keys by virtual keyboard on close.
              release_pressed_on_close = false;
            };

            # ── input:tablet ──
            tablet = {
              # transform the input from tablets.
              # (range: [0, 6])
              transform = 0;
              # the monitor to bind tablets.
              output = "";
              # position of the mapped region in monitor layout.
              # (vec2 range: -20000, -20000, 20000, 20000)
              region_position = "0 0";
              # whether to treat the region_position as an absolute position in monitor layout.
              absolute_region_position = false;
              # size of the mapped region.
              # (vec2 range: -100, -100, 4000, 4000)
              region_size = "0 0";
              # whether the input should be relative
              relative_input = false;
              # if enabled, the tablet will be rotated 180 degrees
              left_handed = false;
              # size of tablet's active area in mm
              # (vec2 range: 0, 0, 500, 500)
              active_area_size = "0 0";
              # position of the active area in mm
              # (vec2 range: 0, 0, 500, 500)
              active_area_position = "0 0";
            };
          };

          # ── gestures ──
          gestures = {
            # in px, the distance of the touchpad gesture
            # (range: [0, 2000])
            workspace_swipe_distance = 300;
            # enable workspace swiping from the edge of a touchscreen
            workspace_swipe_touch = false;
            # invert the direction (touchpad only)
            workspace_swipe_invert = true;
            # invert the direction (touchscreen only)
            workspace_swipe_touch_invert = false;
            # minimum speed in px per timepoint to force the change ignoring cancel_ratio.
            # (range: [0, 200])
            workspace_swipe_min_speed_to_force = 30;
            # how much the swipe has to proceed in order to commence it.
            # (range: [0, 1])
            workspace_swipe_cancel_ratio = 0.5;
            # whether a swipe right on the last workspace should create a new one.
            workspace_swipe_create_new = true;
            # if enabled, switching direction will be locked when you swipe past the direction_lock_threshold.
            workspace_swipe_direction_lock = true;
            # in px, the distance to swipe before direction lock activates.
            # (range: [0, 200])
            workspace_swipe_direction_lock_threshold = 10;
            # if enabled, swiping will not clamp at the neighboring workspaces but continue to the further ones.
            workspace_swipe_forever = false;
            # if enabled, swiping will use the r prefix instead of the m prefix for finding workspaces.
            workspace_swipe_use_r = false;
            # Timeout for closing windows with the close gesture, in ms.
            # (range: [10, 2000])
            close_max_timeout = 1000;

            # ── gestures:scrolling ──
            scrolling = {
              # When releasing the scroll move gesture, whether it shoud try to snap to the grid.
              move_snap_to_grid = true;
              # When releasing the scroll move gesture, whether it shoud snap the cursor to the newly focused window.
              move_snap_cursor = true;
            };
          };

          # ── group ──
          group = {
            # whether new windows in a group spawn after current or at group tail
            insert_after_current = true;
            # whether Hyprland should focus on the window that has just been moved out of the group
            focus_removed_window = true;
            # whether window groups can be dragged into other groups
            merge_groups_on_drag = true;
            # whether one group will be merged with another when dragged into its groupbar
            merge_groups_on_groupbar = true;
            # active group border color
            "col.border_active" = "0x66ffff00"; # 0xAARRGGBB; gradient may be: 'col1 col2 [angle]'
            # inactive group border color
            "col.border_inactive" = "0x66777700"; # 0xAARRGGBB; gradient may be: 'col1 col2 [angle]'
            # inactive locked group border color
            "col.border_locked_inactive" = "0x66ff5500"; # 0xAARRGGBB; gradient may be: 'col1 col2 [angle]'
            # active locked group border color
            "col.border_locked_active" = "0x66775500"; # 0xAARRGGBB; gradient may be: 'col1 col2 [angle]'
            # automatically group new windows
            auto_group = true;
            # whether dragging a window into a unlocked group will merge them.
            # (range: [0, 2])
            drag_into_group = 1;
            # whether dragging a floating window into a tiled window groupbar will merge them
            merge_floated_into_tiled_on_groupbar = false;
            # whether using movetoworkspace[silent] will merge the window into the workspace's solitary unlocked group
            group_on_movetoworkspace = false;

            # ── group:groupbar ──
            groupbar = {
              # enables groupbars
              enabled = true;
              # font used to display groupbar titles
              font_family = "[[EMPTY]]";
              # font size of groupbar title
              # (range: [2, 64])
              font_size = 8;
              # enables gradients
              gradients = false;
              # height of the groupbar
              # (range: [1, 64])
              height = 14;
              # height of the gap between the groupbar indicator and title
              # (range: [0, 64])
              indicator_gap = 0;
              # height of the groupbar indicator
              # (range: [1, 64])
              indicator_height = 3;
              # render the groupbar as a vertical stack
              stacked = false;
              # sets the decoration priority for groupbars
              # (range: [0, 6])
              priority = 3;
              # whether to render titles in the group bar decoration
              render_titles = true;
              # whether scrolling in the groupbar changes group active window
              scrolling = true;
              # whether middle clicking the groupbar closes the clicked window
              middle_click_close = true;
              # how much to round the groupbar
              # (range: [0, 20])
              rounding = 1;
              # rounding power of groupbar corners (2 is a circle)
              # (range: [2, 10])
              rounding_power = 2;
              # how much to round the groupbar gradient
              # (range: [0, 20])
              gradient_rounding = 2;
              # rounding power of groupbar gradient corners (2 is a circle)
              # (range: [2, 10])
              gradient_rounding_power = 2;
              # if yes, will only round at the groupbar edges
              round_only_edges = true;
              # if yes, will only round at the groupbar gradient edges
              gradient_round_only_edges = true;
              # color for window titles in the groupbar
              text_color = "0xffffffff"; # 0xAARRGGBB
              # color for inactive windows' titles in the groupbar
              text_color_inactive = -1; # sentinel: inherit from related color
              # color for the active window's title in a locked group
              text_color_locked_active = -1; # sentinel: inherit from related color
              # color for inactive windows' titles in locked groups
              text_color_locked_inactive = -1; # sentinel: inherit from related color
              # active group border color
              "col.active" = "0x66ffff00"; # 0xAARRGGBB
              # inactive (out of focus) group border color
              "col.inactive" = "0x66777700"; # 0xAARRGGBB
              # active locked group border color
              "col.locked_active" = "0x66ff5500"; # 0xAARRGGBB
              # inactive locked group border color
              "col.locked_inactive" = "0x66775500"; # 0xAARRGGBB
              # gap between gradients and window
              # (range: [0, 20])
              gaps_out = 2;
              # gap between gradients
              # (range: [0, 20])
              gaps_in = 2;
              # keep an upper gap above gradient
              keep_upper_gap = true;
              # set an offset for a text
              # (range: [-20, 20])
              text_offset = 0;
              # set horizontal padding for a text
              # (range: [0, 22])
              text_padding = 0;
              # enable background blur for groupbars
              blur = false;
              # weight of the font used to display active groupbar titles
              font_weight_active = 400;
              # weight of the font used to display inactive groupbar titles
              font_weight_inactive = 400;
            };
          };

          # ── misc ──
          misc = {
            # disables the random Hyprland logo / anime girl background. :(
            disable_hyprland_logo = false;
            # disables the Hyprland splash rendering.
            disable_splash_rendering = false;
            # Changes the color of the splash text.
            "col.splash" = "0x55ffffff"; # 0xAARRGGBB
            # Set the global default font to render the text.
            font_family = "Sans";
            # Changes the font used to render the splash text.
            splash_font_family = "[[EMPTY]]";
            # Force any of the 3 default wallpapers. [-1/0/1/2]
            # (range: [-1, 2])
            force_default_wallpaper = -1;
            # controls the VRR (Adaptive Sync) of your monitors
            # (range: [0, 3])
            vrr = 0;
            # If DPMS is set to off, wake up the monitors if the mouse moves
            mouse_move_enables_dpms = false;
            # If DPMS is set to off, wake up the monitors if a key is pressed.
            key_press_enables_dpms = false;
            # Name virtual keyboards after the processes that create them.
            name_vk_after_proc = true;
            # Will make mouse focus follow the mouse when drag and dropping.
            always_follow_on_dnd = true;
            # If true, will make keyboard-interactive layers keep their focus on mouse move.
            layers_hog_keyboard_focus = true;
            # If true, will animate manual window resizes/moves
            animate_manual_resizes = false;
            # If true, will animate windows being dragged by mouse.
            animate_mouse_windowdragging = false;
            # If true, the config will not reload automatically on save.
            disable_autoreload = false;
            # Enable window swallowing
            enable_swallow = false;
            # The class regex to be used for windows that should be swallowed.
            swallow_regex = "";
            # The title regex to be used for windows that should not be swallowed.
            swallow_exception_regex = "";
            # Whether Hyprland should focus an app that requests to be focused.
            focus_on_activate = false;
            # Whether mouse moving into a different monitor should focus it
            mouse_move_focuses_monitor = true;
            # if true, will allow you to restart a lockscreen app in case it crashes.
            allow_session_lock_restore = false;
            # keep rendering workspaces below your lockscreen
            session_lock_xray = false;
            # change the background color.
            background_color = "0xff111111"; # 0xAARRGGBB
            # close the special workspace if the last window is removed
            close_special_on_empty = true;
            # if there is a fullscreen or maximized window, decide whether a tiled window requested to focus should replace it.
            # (range: [0, 2])
            on_focus_under_fullscreen = 2;
            # if true, closing a fullscreen window makes the next focused window fullscreen
            exit_window_retains_fullscreen = false;
            # if enabled, windows will open on the workspace they were invoked on.
            # (range: [0, 2])
            initial_workspace_tracking = 1;
            # whether to enable middle-click-paste (aka primary selection)
            middle_click_paste = true;
            # the maximum limit for renderunfocused windows' fps in the background
            # (range: [1, 120])
            render_unfocused_fps = 15;
            # disable the warning if XDG environment is externally managed
            disable_xdg_env_checks = false;
            # disable the warning if hyprland-guiutils is missing
            disable_hyprland_guiutils_check = false;
            # whether to disable the warning about not using start-hyprland.
            disable_watchdog_warning = false;
            # the delay in ms after the lockdead screen appears.
            # (range: [0, 5000])
            lockdead_screen_delay = 1000;
            # whether to enable the ANR (app not responding) dialog when your apps hang
            enable_anr_dialog = true;
            # number of missed pings before showing the ANR dialog
            # (range: [1, 20])
            anr_missed_pings = 5;
            # forces 8 bit screencopy
            screencopy_force_8b = true;
            # disables notification popup when a monitor fails to set a suitable scale
            disable_scale_notification = false;
            # whether to apply minsize and maxsize rules to tiled windows
            size_limits_tiled = false;
          };

          # ── binds ──
          binds = {
            # if disabled, will not pass the mouse events to apps / dragging windows around if a keybind has been triggered.
            pass_mouse_when_bound = false;
            # in ms, how many ms to wait after a scroll event to allow passing another one for the binds.
            # (range: [0, 2000])
            scroll_event_delay = 300;
            # If enabled, an attempt to switch to the currently focused workspace will instead switch to the previous workspace.
            workspace_back_and_forth = false;
            # If enabled, changing the active workspace will hide the special workspace on the monitor.
            hide_special_on_workspace_change = false;
            # If enabled, workspaces don't forget their previous workspace.
            allow_workspace_cycles = false;
            # Whether switching workspaces should center the cursor on the workspace (0) or on the last active window (1)
            # (range: [0, 1])
            workspace_center_on = 1;
            # sets the preferred focus finding method when using focuswindow/movewindow/etc with a direction.
            # (range: [0, 1])
            focus_preferred_method = 0;
            # If enabled, dispatchers like moveintogroup, moveoutofgroup and movewindoworgroup will ignore lock per group.
            ignore_group_lock = false;
            # If enabled, when on a fullscreen window, movefocus will cycle fullscreen.
            movefocus_cycles_fullscreen = false;
            # If enabled, when in a grouped window, movefocus will cycle windows in the groups first.
            movefocus_cycles_groupfirst = false;
            # If enabled, apps that request keybinds to be disabled will not be able to do so.
            disable_keybind_grabbing = false;
            # If enabled, moving a window or focus over the edge of a monitor with a direction will move it to the next monitor.
            window_direction_monitor_fallback = true;
            # Allows fullscreen to pinned windows, and restore their pinned status afterwards
            allow_pin_fullscreen = false;
            # Movement threshold in pixels for window dragging and c/g bind flags. 0 to disable.
            # (range: [0, INT_MAX])
            drag_threshold = 0;
          };

          # ── xwayland ──
          xwayland = {
            # allow running applications using X11
            enabled = true;
            # uses the nearest neighbor filtering for xwayland apps, making them pixelated rather than blurry
            use_nearest_neighbor = true;
            # forces a scale of 1 on xwayland windows on scaled displays.
            force_zero_scaling = false;
            # Create the abstract Unix domain socket for XWayland
            create_abstract_socket = false;
          };

          # ── opengl ──
          opengl = {
            # reduces flickering on nvidia at the cost of possible frame drops on lower-end GPUs.
            nvidia_anti_flicker = true;
          };

          # ── render ──
          render = {
            # Enables direct scanout.
            # (range: [0, 2])
            direct_scanout = 0;
            # Whether to expand textures that have not yet resized to be larger.
            expand_undersized_textures = true;
            # Disable back buffer and bottom layer rendering.
            xp_mode = false;
            # Whether to enable a fade animation for CTM changes.
            # (range: [0, 2])
            ctm_animation = 2;
            # Enable Color Management pipelines (requires restart to fully take effect)
            cm_enabled = true;
            # Report content type to allow monitor profile autoswitch
            send_content_type = true;
            # Auto-switch to hdr mode when fullscreen app is in hdr
            # (range: [0, 2])
            cm_auto_hdr = 1;
            # enable new render scheduling, which should improve FPS on underpowered devices.
            new_render_scheduling = false;
            # Enable CM without shader.
            # (range: [0, 3])
            non_shader_cm = 3;
            # Default transfer function for displaying SDR apps.
            cm_sdr_eotf = "default";
            # Enable commit timing proto. Requires restart
            commit_timing_enabled = true;
            # Enable sending VCGT ramps to KMS with ICC profiles
            icc_vcgt_enabled = true;
            # Use experimental blurred bg blending
            use_shader_blur_blend = false;
            # Use experimental internal FP16 buffer.
            # (range: [0, 2])
            use_fp16 = 2;
            # Keep umodified SDR frame copy for sreensharing.
            # (range: [0, 2])
            keep_unmodified_copy = 2;
            # non_shader_cm interaction with ctm proto (hyprsunset and similar).
            # (range: [0, 2])
            non_shader_cm_interop = 2;
            # Internal workbuffer transfer function for fp16 in SDR mode
            # (range: [0, 1])
            fp16_sdr_tf = 0;
          };

          # ── cursor ──
          cursor = {
            # don't render cursors
            invisible = false;
            # disables hardware cursors.
            # (range: [0, 2])
            no_hardware_cursors = 2;
            # disables scheduling new frames on cursor movement for fullscreen apps with VRR enabled.
            # (range: [0, 2])
            no_break_fs_vrr = 2;
            # minimum refresh rate for cursor movement when no_break_fs_vrr is active.
            # (range: [10, 500])
            min_refresh_rate = 24;
            # the padding, in logical px, between screen edges and the cursor
            # (range: [0, 20])
            hotspot_padding = 0;
            # in seconds, after how many seconds of cursor's inactivity to hide it. Set to 0 for never.
            # (range: [0, 20])
            inactive_timeout = 0;
            # if true, will not warp the cursor in many cases
            no_warps = false;
            # When a window is refocused, the cursor returns to its last position relative to that window.
            persistent_warps = false;
            # Move the cursor to the last focused window after changing the workspace.
            # (range: [0, 2])
            warp_on_change_workspace = 0;
            # Move the cursor to the last focused window when toggling a special workspace.
            # (range: [0, 2])
            warp_on_toggle_special = 0;
            # the name of a default monitor for the cursor to be set to on startup
            default_monitor = "";
            # the factor to zoom by around the cursor. 1 means no zoom.
            # (range: [1, 10])
            zoom_factor = 1;
            # whether the zoom should follow the cursor rigidly or loosely
            zoom_rigid = false;
            # If enabled, when zooming, no antialiasing will be used
            zoom_disable_aa = false;
            # Detaches the camera from the mouse when zoomed in
            zoom_detached_camera = true;
            # whether to enable hyprcursor support
            enable_hyprcursor = true;
            # Hides the cursor when you press any key until the mouse is moved.
            hide_on_key_press = false;
            # Hides the cursor when the last input was a touch input until a mouse input is done.
            hide_on_touch = true;
            # Hides the cursor when the last input was a tablet input until a mouse input is done.
            hide_on_tablet = false;
            # Makes HW cursors use a CPU buffer.
            # (range: [0, 2])
            use_cpu_buffer = 2;
            # sync xcursor theme with gsettings
            sync_gsettings_theme = true;
            # warp the cursor back to where it was after using a non-mouse input to move it.
            warp_back_after_non_mouse_input = false;
          };

          # ── ecosystem ──
          ecosystem = {
            # disable the popup that shows up when you update hyprland to a new version.
            no_update_news = false;
            # disable the popup that shows up twice a year encouraging to donate.
            no_donation_nag = false;
            # whether to enable permission control.
            enforce_permissions = false;
          };

          # ── debug ──
          debug = {
            # print the debug performance overlay.
            overlay = false;
            # flash damaged areas
            damage_blink = false;
            # enable OpenGL debugging and error checking.
            gl_debugging = false;
            # disable logging to a file
            disable_logs = true;
            # disables time logging
            disable_time = true;
            # redraw only the needed bits of the display.
            # (range: [0, 2])
            damage_tracking = 2;
            # enables logging to stdout
            enable_stdout_logs = false;
            # set to 1 and then back to 0 to crash Hyprland.
            # (range: [0, 1])
            manual_crash = 0;
            # if true, do not display config file parsing errors.
            suppress_errors = false;
            # disables verification of the scale factors.
            disable_scale_checks = false;
            # limits the number of displayed config file parsing errors.
            # (range: [0, 20])
            error_limit = 5;
            # sets the position of the error bar.
            # (range: [0, 1])
            error_position = 0;
            # enables colors in the stdout logs.
            colored_stdout_logs = true;
            # enables logging the damage.
            log_damage = false;
            # enables render pass debugging.
            pass = false;
            # claims support for all cm proto features (requires restart)
            full_cm_proto = false;
            # Special case for DS with unmodified buffer
            ds_handle_same_buffer = true;
            # Special case for DS with unmodified buffer unlocks fifo
            ds_handle_same_buffer_fifo = true;
            # Fifo workaround for empty pending list
            fifo_pending_workaround = false;
            # Render solitary window with empty damage
            render_solitary_wo_damage = false;
            # controls the VFR status of Hyprland. Do not turn off unless debugging
            vfr = true;
            # allow fp16 buffer invalidation.
            # (range: [0, 2])
            invalidate_fp16 = 1;
          };

          # ── layout ──
          layout = {
            # If specified, whenever only a single window is open, it will be coerced into the specified aspect ratio.
            # (vec2 range: 0, 0, 1000, 1000)
            single_window_aspect_ratio = "0 0";
            # Minimum distance for single_window_aspect_ratio to take effect.
            # (range: [0., 1.])
            single_window_aspect_ratio_tolerance = 0.1;
          };

          # ── dwindle ──
          dwindle = {
            # force a split direction for new windows
            # (range: [0, 2])
            force_split = 0;
            # if enabled, the split will not change regardless of what happens to the container.
            preserve_split = false;
            # if enabled, allows a more precise control over the window split direction based on the cursor's position.
            smart_split = false;
            # if enabled, resizing direction will be determined by the mouse's position on the window.
            smart_resizing = true;
            # if enabled, makes the preselect direction persist.
            permanent_direction_override = false;
            # specifies the scale factor of windows on the special workspace
            # (range: [0, 1])
            special_scale_factor = 1;
            # specifies the auto-split width multiplier
            # (range: [0.1, 3])
            split_width_multiplier = 1;
            # whether to prefer the active window or the mouse position for splits
            use_active_for_splits = true;
            # the default split ratio on window open.
            # (range: [0.1, 1.9])
            default_split_ratio = 1;
            # specifies which window will receive the split ratio.
            # (range: [0, 1])
            split_bias = 0;
            # if enabled, bindm movewindow will drop the window more precisely depending on where your mouse is.
            precise_mouse_move = false;
          };

          # ── master ──
          master = {
            # enable adding additional master windows in a horizontal split style
            allow_small_split = false;
            # the scale of the special workspace windows.
            # (range: [0, 1])
            special_scale_factor = 1;
            # the size as a percentage of the master window.
            # (range: [0, 1])
            mfact = 0.55;
            # `master`: new window becomes master; `slave`: new windows are added to slave stack; `inherit`: inherit from focused window
            new_status = "slave";
            # whether a newly open window should be on the top of the stack
            new_on_top = false;
            # `before`, `after`: place new window relative to the focused window; `none`: place new window according to new_on_top.
            new_on_active = "none";
            # default placement of the master area
            orientation = "left";
            # when using orientation=center, make the master window centered only when at least this many slave windows are open.
            # (range: [0, 10])
            slave_count_for_center_master = 2;
            # Set fallback for center master when slaves are less than slave_count_for_center_master
            center_master_fallback = "left";
            # centers the master window on monitor ignoring reserved areas
            center_ignores_reserved = false;
            # if enabled, resizing direction will be determined by the mouse's position on the window.
            smart_resizing = true;
            # when enabled, dragging and dropping windows will put them at the cursor position.
            drop_at_cursor = true;
            # whether to keep the master window in its configured position when there are no slave windows
            always_keep_position = false;
          };

          # ── scrolling ──
          scrolling = {
            # when enabled, a single column on a workspace will always span the entire screen.
            fullscreen_on_one_column = true;
            # the default width of a column.
            # (range: [0.1, 1.0])
            column_width = 0.5;
            # When a column is focused, what method should be used to bring it into view
            # (range: [0, 1])
            focus_fit_method = 1;
            # when a window is focused, should the layout move to bring it into view automatically
            follow_focus = true;
            # when a window is focused, require that at least a given fraction of it is visible for focus to follow
            # (range: [0.0, 1.0])
            follow_min_visible = 0.4;
            # A comma-separated list of preconfigured widths for colresize +conf/-conf
            explicit_column_widths = "0.333, 0.5, 0.667, 1.0";
            # Direction in which new windows appear and the layout scrolls
            direction = "right";
            # Determines if column focus wraps around
            wrap_focus = true;
            # Determines if column movement wraps around
            wrap_swapcol = true;
          };

          # ── experimental ──
          experimental = {
            # Allow wp-cm-v1 version 2
            wp_cm_1_2 = false;
          };

          # ── quirks ──
          quirks = {
            # Prefer HDR mode.
            # (range: [0, 2])
            prefer_hdr = 0;
            # Do not report dmabuf formats which cannot be imported into KMS
            skip_non_kms_dmabuf_formats = false;
          };

          # ── Dynamic / list-valued keywords ──
          # These don't have defaults; they're additive directives. Set them
          # to lists of strings; HM emits one line per element.

          # Programs to launch every time Hyprland starts (re-run on reload).
          exec = [
            # "swww init"
          ];

          # Programs to launch ONCE at session startup.
          exec-once = [
            # "waybar"
            # "dunst"
            # "hyprpaper"
          ];

          # Run a raw command (no shell wrapper) every reload.
          execr = [ ];

          # Run a raw command (no shell wrapper) once at startup.
          execr-once = [ ];

          # Programs to run when Hyprland shuts down.
          exec-shutdown = [ ];

          # Monitor configuration. Format:
          #   "NAME,RESOLUTION@RATE,POSITION,SCALE[,additional...]"
          # Use ",preferred,auto,1" as a generic fallback rule.
          monitor = [
            ",preferred,auto,1"
          ];

          # Environment variables exported to the session. Format: "KEY,VALUE".
          env = [
            # "XCURSOR_SIZE,24"
            # "QT_QPA_PLATFORMTHEME,qt5ct"
          ];

          # Keybinds. Format: "MODS, KEY, dispatcher, args"
          # Bind flags can be appended after the b: e.g. "binde", "bindm" (mouse),
          # "bindr" (release), "bindl" (locked), "binds" (silent), "bindo"
          # (operating-in-fullscreen), "bindi" (ignore mods), "bindn" (no mods),
          # "bindp" (pass through), "bindc" (click), "bindg" (group).
          bind = [
            # "SUPER, Q, exec, kitty"
            # "SUPER, M, exit,"
          ];

          # Explicitly unbind a key.
          unbind = [ ];

          # Per-workspace rules. Format: "WORKSPACE_ID_OR_NAME, rule1, rule2, ..."
          workspace = [ ];

          # Window rules (v3 / unified). Format: "RULE, MATCHER" or with the
          # newer named-property syntax. See wiki for full list of properties
          # (float, tile, opacity, monitor, workspace, size, move, center, ...).
          windowrule = [ ];

          # Layer rules. Format: "RULE, NAMESPACE_REGEX".
          layerrule = [ ];

          # Custom bezier curves for animations. Format: "name, x1, y1, x2, y2"
          bezier = [
            # "myBezier, 0.05, 0.9, 0.1, 1.05"
          ];

          # Animation overrides. Format:
          #   "NAME, ON/OFF, DURATION_IN_DS, BEZIER_NAME [, STYLE]"
          # DURATION is in deciseconds (1ds = 100ms).
          animation = [
            # "windows,    1, 7, myBezier"
            # "windowsOut, 1, 7, default, popin 80%"
            # "border,     1, 10, default"
            # "fade,       1, 7, default"
            # "workspaces, 1, 6, default"
          ];

          # Submaps — modal binding contexts. Use the `submap` dispatcher to
          # enter one. With `settings`, you typically just declare the names
          # and put binds inside a raw `extraConfig` block, since hyprlang's
          # submap syntax is positional.
          submap = [ ];

          # Plugin paths (.so files) to load.
          plugin = [ ];

          # Permission rules. Format: "REGEX, CAPABILITY, MODE".
          permission = [ ];

          # Touchpad gestures. Format follows the wiki's `gesture =` syntax,
          # e.g. "3, horizontal, workspace".
          gesture = [ ];
        };

        # If you have anything that doesn't fit the structured `settings`
        # above (raw hyprlang blocks like `submap = NAME { ... }`), put it
        # here.
        extraConfig = ''
          # submap = resize
          # binde = , right, resizeactive, 10 0
          # binde = , left,  resizeactive, -10 0
          # submap = reset
        '';
      };
    };
}
