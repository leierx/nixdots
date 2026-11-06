{ inputs, ... }:
{
  flake.modules.homeManager.herdr =
    { pkgs, ... }:
    {
      # release-26.05 lacks programs.herdr and the two generators it calls
      imports = [
        (
          {
            config,
            lib,
            pkgs,
            ...
          }:
          import "${inputs.home-manager-unstable}/modules/programs/herdr.nix" {
            inherit config pkgs;
            lib = lib // {
              hm = lib.hm // {
                generators = lib.hm.generators // {
                  inherit (import "${inputs.home-manager-unstable}/modules/lib/generators.nix" { inherit lib; })
                    mkImpureConfigMerger
                    mkImpureConfigCleanup
                    ;
                };
              };
            };
          }
        )
      ];

      programs.herdr = {
        enable = true;

        # nullable; unstable adds the Linux notify-send fix for ui.toast.delivery = "system"
        package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.herdr;

        # false (default): config.toml is a read-only store link and herdr's own
        #   Settings writes (theme, status_indicators, sound, toast delivery,
        #   onboarding) fail; `herdr server reload-config` runs on change.
        # true: declared settings are merged into a writable 0600 file on every
        #   switch (declared wins, arrays included); keys herdr or you add survive,
        #   removed declarations are NOT deleted, comments/formatting are lost.
        # settings = { } leaves the file unmanaged in both modes.
        # mutableSettings = false;

        # Written to $XDG_CONFIG_HOME/herdr/config.toml (HERDR_CONFIG_PATH overrides
        # where herdr reads it). Values below are herdr 0.9.5's defaults; "unset"
        # means the key is absent by default. Reference: https://herdr.dev/docs/config-reference/
        # and `herdr --default-config`. Client-side keys (theme, ui, keys, sound)
        # come from the local config even when attached with `herdr --remote`;
        # terminal, worktrees, custom commands and integrations from the server's.
        settings = {
          # Missing/true shows first-run setup; finishing it writes false.
          # onboarding = false;

          # server = {
          #   allow_unelevated_clients = false; # Windows only; restart to apply
          #   headless_cols = 120; # layout size while no client is attached
          #   headless_rows = 40;
          # };

          # theme = {
          #   # catppuccin catppuccin-latte terminal tokyo-night tokyo-night-day dracula
          #   # nord gruvbox gruvbox-light one-dark one-light solarized solarized-light
          #   # kanagawa kanagawa-lotus rose-pine rose-pine-dawn vesper
          #   # "terminal" follows the host terminal's ANSI palette.
          #   name = "catppuccin";
          #   auto_switch = false; # follow the host terminal's light/dark reports
          #   dark_name = "catppuccin"; # unset: sibling of name
          #   light_name = "catppuccin-latte"; # unset: sibling of name
          #   # Colours: hex, named, "rgb(r,g,b)", or reset/default/none/transparent.
          #   # Tokens: accent panel_bg sidebar_bg active_row_bg selection_bg surface0
          #   # surface1 surface_dim overlay0 overlay1 text subtext0 mauve green
          #   # yellow red blue teal peach. Order: theme, custom, custom.light/dark.
          #   custom = {
          #     sidebar_bg = "#181825"; # unset: host terminal background
          #     panel_bg = "reset";
          #     accent = "#a6e3a1";
          #     light = { text = "#4c4f69"; }; # only with auto_switch
          #     dark = { text = "#cdd6f4"; };
          #   };
          # };

          # terminal = {
          #   default_shell = ""; # executable, not a command line; "" = $SHELL, then /bin/sh
          #   shell_mode = "auto"; # auto (login on macOS) | login | non_login
          #   new_cwd = "follow"; # follow | home | current | a path like "~/Projects"
          #   kitty_graphics = true; # restart server / reattach to apply
          # };

          # update = {
          #   channel = "stable"; # stable | preview; Nix installs ignore preview
          #   version_check = true; # background check against herdr.dev
          #   manifest_check = true; # agent-detection manifest updates from herdr.dev
          # };

          # Bindings: "prefix+x" needs the prefix, "ctrl+alt+x" is direct, a list
          # binds several, "" unbinds. Keys: plain, ctrl/shift/alt/cmd/super+,
          # enter tab esc left right up down, minus comma ampersand plus backtick.
          # `herdr config reset-keys` rewrites the file without [keys].
          # keys = {
          #   prefix = "ctrl+b"; # or a list, e.g. [ "ctrl+space" "ctrl+s" ]
          #   help = "prefix+?";
          #   settings = "prefix+s";
          #   detach = "prefix+q";
          #   reload_config = "prefix+shift+r";
          #   open_notification_target = "prefix+o";
          #   workspace_picker = "prefix+w";
          #   goto = "prefix+g";
          #   new_workspace = "prefix+shift+n";
          #   new_worktree = "prefix+shift+g";
          #   open_worktree = ""; # unset
          #   remove_worktree = ""; # unset; asks for confirmation
          #   rename_workspace = "prefix+shift+w";
          #   close_workspace = "prefix+shift+d";
          #   previous_workspace = ""; # unset
          #   next_workspace = ""; # unset
          #   switch_workspace = ""; # unset; e.g. "prefix+shift+1..9"
          #   previous_agent = ""; # unset
          #   next_agent = ""; # unset
          #   focus_agent = ""; # unset; e.g. "prefix+alt+1..9"
          #   remote_image_paste = "ctrl+v"; # herdr --remote only; "" disables
          #   new_tab = "prefix+c";
          #   rename_tab = "prefix+shift+t";
          #   previous_tab = "prefix+p";
          #   next_tab = "prefix+n";
          #   move_tab_previous = ""; # unset; e.g. "alt+shift+left"
          #   move_tab_next = ""; # unset
          #   switch_tab = "prefix+1..9";
          #   close_tab = "prefix+shift+x";
          #   rename_pane = "prefix+shift+p";
          #   edit_scrollback = "prefix+e"; # opens scrollback in $EDITOR
          #   clear_pane = ""; # unset; e.g. "prefix+ctrl+k"
          #   copy_mode = "prefix+[";
          #   focus_pane_left = "prefix+h";
          #   focus_pane_down = "prefix+j";
          #   focus_pane_up = "prefix+k";
          #   focus_pane_right = "prefix+l";
          #   swap_pane_left = "prefix+shift+h";
          #   swap_pane_down = "prefix+shift+j";
          #   swap_pane_up = "prefix+shift+k";
          #   swap_pane_right = "prefix+shift+l";
          #   cycle_pane_next = "prefix+tab";
          #   cycle_pane_previous = "prefix+shift+tab";
          #   last_pane = ""; # unset; across workspaces and tabs
          #   split_vertical = "prefix+v"; # side by side
          #   split_horizontal = "prefix+minus"; # stacked
          #   close_pane = "prefix+x";
          #   zoom = "prefix+z"; # legacy name: fullscreen
          #   resize_mode = "prefix+r";
          #   resize_pane_left = ""; # unset; e.g. "ctrl+shift+alt+left"
          #   resize_pane_down = "";
          #   resize_pane_up = "";
          #   resize_pane_right = "";
          #   toggle_sidebar = "prefix+b";
          #   # Navigate mode only; plain keys allowed, but no prefix+, esc, enter,
          #   # tab, shift+tab, left, right or bare 1-9. Arrows always alias h/l.
          #   navigate_workspace_up = "up";
          #   navigate_workspace_down = "down";
          #   navigate_pane_left = "h";
          #   navigate_pane_down = "j";
          #   navigate_pane_up = "k";
          #   navigate_pane_right = "l";
          #   # Legacy; prefer switch_tab / switch_workspace / focus_agent.
          #   indexed = {
          #     tabs = ""; # e.g. "ctrl" -> ctrl+1..9
          #     workspaces = "";
          #     agents = "";
          #   };
          #   # Env: HERDR_SOCKET_PATH HERDR_BIN_PATH HERDR_ACTIVE_{WORKSPACE,TAB,PANE}_ID
          #   # HERDR_ACTIVE_PANE_CWD. Runs via /bin/sh -c (detached: -lc).
          #   command = [
          #     {
          #       key = "prefix+alt+g";
          #       type = "popup"; # popup | pane (temporary zoomed) | shell (detached) | plugin_action
          #       command = "lazygit"; # plugin_action: the action id, e.g. "example.layout.apply"
          #       description = "run lazygit"; # shown in prefix+? help
          #       width = "80%"; # popup only: cells or "N%"; default half size
          #       height = "80%";
          #     }
          #   ];
          # };

          # ui = {
          #   sidebar_width = 26; # auto-scales with workspace names
          #   sidebar_min_width = 18;
          #   sidebar_max_width = 36;
          #   sidebar_start_collapsed = false; # next launch
          #   sidebar_collapsed_mode = "compact"; # compact | hidden
          #   mobile_width_threshold = 64; # single-column layout at or below
          #   mouse_capture = true; # false: terminal handles clicks (Cmd-click URLs)
          #   copy_on_select = true;
          #   host_cursor = "auto"; # auto | native | drawn
          #   right_click_passthrough_modifier = ""; # ctrl alt cmd super meta hyper, "+"-joined
          #   redraw_on_focus_gained = true;
          #   mouse_scroll_lines = 3;
          #   confirm_close = true; # closing a workspace
          #   prompt_new_tab_name = true;
          #   prompt_new_workspace_name = false;
          #   pane_borders = "auto"; # auto | always | off
          #   pane_outer_borders = true;
          #   pane_scrollbars = true;
          #   pane_gaps = true; # false + pane_outer_borders = false: tmux-style splitters
          #   show_agent_labels_on_pane_borders = false;
          #   hide_tab_bar_when_single_tab = false;
          #   tab_bar_position = "top"; # top | bottom
          #   tab_bar_right = [
          #     { type = "zoom"; }
          #     { type = "hostname"; }
          #     { type = "datetime"; format = "%H:%M"; } # no %z / %s
          #     { type = "text"; text = "prod"; }
          #     {
          #       type = "command"; # last stdout line, /bin/sh -lc, on the server
          #       command = "~/.config/herdr/status.sh";
          #       interval_seconds = 5; # 1-31536000
          #       timeout_seconds = 2; # 1-3600
          #     }
          #   ];
          #   tab_bar_right_separator = " ";
          #   window_title = "{hostname}: {workspace}"; # {tab} {pane} {terminal_title}; "" leaves it alone
          #   agent_panel_sort = "spaces"; # spaces | priority
          #   status_indicators = "dots"; # dots | symbols
          #   accent = "cyan";
          #   # Rows are lists of tokens; a token may be { token; fg = "#RGB"; bold; dim;
          #   # rules = [ { equals|contains|starts_with|gt|lt = ...; ignore_case; fg; bold; dim; hide; } ]; }.
          #   # Agent tokens: state_icon state_text machine workspace tab pane agent
          #   # terminal_title terminal_title_stripped $name. Max 16 rows x 16 tokens.
          #   sidebar.agents = {
          #     row_gap = 0;
          #     rows = [
          #       [ "state_icon" "machine" "workspace" "tab" ]
          #       [ "agent" ]
          #     ];
          #     rows_by_agent = {
          #       pi = [
          #         [ "state_icon" "agent" "state_text" ]
          #         [ "terminal_title_stripped" ]
          #       ];
          #     };
          #   };
          #   # Space tokens: state_icon state_text workspace branch git_status $name.
          #   sidebar.spaces = {
          #     row_gap = 0;
          #     rows = [
          #       [ "state_icon" "workspace" ]
          #       [ "branch" "git_status" ]
          #     ];
          #   };
          #   toast = {
          #     delivery = "off"; # off | herdr | terminal | system
          #     delay_seconds = 1; # 0-3600
          #     herdr.position = "bottom-right"; # top-left top-right bottom-left bottom-right
          #     clipboard = {
          #       enabled = true;
          #       position = "bottom-center"; # also top-center
          #     };
          #   };
          #   sound = {
          #     enabled = true; # background workspaces only; HERDR_DISABLE_SOUND overrides
          #     path = "sounds/notification.mp3"; # unset; mp3, relative to config dir
          #     done_path = "sounds/done.mp3"; # unset
          #     request_path = "sounds/request.mp3"; # unset
          #     # default | on | off. Agents: pi claude codex gemini cursor devin agy
          #     # cline open_code github_copilot kimi kiro droid amp grok hermes kilo
          #     # qodercli qwen letta maki muse.
          #     agents = {
          #       droid = "off";
          #     };
          #   };
          # };

          # session = {
          #   resume_agents_on_restore = true;
          #   startup_per_agent_delay_ms = 100; # restart server to apply
          # };

          # worktrees.directory = "~/.herdr/worktrees"; # <dir>/<repo>/<branch-slug>

          # remote.manage_ssh_config = true; # keepalives + ControlMaster for herdr --remote

          # advanced.scrollback_limit_bytes = 10000000; # per pane; legacy name scrollback_lines

          # experimental = {
          #   allow_nested = false;
          #   pane_history = false; # persists pane contents to session-history.json
          #   reveal_hidden_cursor_for_cjk_ime = false; # macOS IME anchor for agent TUIs
          #   cjk_ime_agents = [ ]; # e.g. [ "pi" "claude" ]; [ ] = any pane
          #   cjk_ime_cursor_shape = "steady_block"; # block steady_block underline steady_underline bar steady_bar
          #   switch_ascii_input_source_in_prefix = false; # macOS / Windows Korean IME
          # };
        };
      };
    };
}
