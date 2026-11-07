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
        package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.herdr;
        settings = {
          onboarding = false;
          theme = {
            name = "kanagawa";
            custom.sidebar_bg = "#1f1f28"; # kanagawa's sumiInk3, = its panel_bg
          };

          update = {
            version_check = false;
          };

          keys = {
            prefix = "ctrl+b";
            help = "prefix+?";
            settings = "";
            detach = "prefix+q";
            reload_config = "prefix+shift+r";
            open_notification_target = "prefix+o";
            workspace_picker = "prefix+w"; # maybe "/" in the future
            goto = "prefix+g";
            new_workspace = "prefix+shift+n";
            new_worktree = "prefix+shift+g";
            open_worktree = ""; # unset
            remove_worktree = ""; # unset; asks for confirmation
            rename_workspace = "prefix+shift+w";
            close_workspace = "prefix+shift+d";
            previous_workspace = ""; # unset
            next_workspace = ""; # unset
            switch_workspace = ""; # unset; e.g. "prefix+shift+1..9"
            previous_agent = ""; # unset
            next_agent = ""; # unset
            focus_agent = ""; # unset; e.g. "prefix+alt+1..9"
            remote_image_paste = "ctrl+v"; # herdr --remote only; "" disables
            new_tab = "prefix+c";
            rename_tab = "prefix+shift+t";
            previous_tab = "prefix+p";
            next_tab = "prefix+n";
            move_tab_previous = ""; # unset; e.g. "alt+shift+left"
            move_tab_next = ""; # unset
            switch_tab = "prefix+1..9";
            close_tab = "prefix+shift+x";
            rename_pane = "prefix+shift+p";
            edit_scrollback = "prefix+e"; # opens scrollback in $EDITOR
            clear_pane = ""; # unset; e.g. "prefix+ctrl+k"
            copy_mode = "prefix+y"; # "[" needs AltGr on the no layout
            focus_pane_left = "prefix+h";
            focus_pane_down = "prefix+j";
            focus_pane_up = "prefix+k";
            focus_pane_right = "prefix+l";
            swap_pane_left = "prefix+shift+h";
            swap_pane_down = "prefix+shift+j";
            swap_pane_up = "prefix+shift+k";
            swap_pane_right = "prefix+shift+l";
            cycle_pane_next = "prefix+tab";
            cycle_pane_previous = "prefix+shift+tab";
            last_pane = ""; # unset; across workspaces and tabs
            split_vertical = "prefix+v"; # side by side
            split_horizontal = "prefix+minus"; # stacked
            close_pane = "prefix+x";
            zoom = "prefix+z"; # legacy name: fullscreen
            resize_mode = "prefix+r"; # h/j/k/l resize; esc, enter or prefix+r leaves
            toggle_sidebar = "prefix+b";
            navigate_workspace_up = "u";
            navigate_workspace_down = "d";
            navigate_pane_left = "h";
            navigate_pane_down = "j";
            navigate_pane_up = "k";
            navigate_pane_right = "l";
          };

          ui = {
            sidebar_width = 26;
            sidebar_min_width = 18;
            sidebar_max_width = 36;
            sidebar_start_collapsed = false; # next launch
            sidebar_collapsed_mode = "compact"; # compact | hidden
            mobile_width_threshold = 64; # single-column layout at or below
            mouse_capture = true; # false: terminal handles clicks (Cmd-click URLs)
            copy_on_select = true;
            host_cursor = "auto"; # auto | native | drawn
            right_click_passthrough_modifier = ""; # ctrl alt cmd super meta hyper, "+"-joined
            redraw_on_focus_gained = true;
            mouse_scroll_lines = 3;
            confirm_close = true; # closing a workspace
            prompt_new_tab_name = true;
            prompt_new_workspace_name = false;
            pane_borders = "auto"; # auto | always | off
            pane_outer_borders = true;
            pane_scrollbars = true;
            pane_gaps = true; # false + pane_outer_borders = false: tmux-style splitters
            show_agent_labels_on_pane_borders = false;
            hide_tab_bar_when_single_tab = false;
            tab_bar_position = "top"; # top | bottom
            tab_bar_right = [
              { type = "zoom"; }
              { type = "hostname"; }
              {
                type = "datetime";
                format = "%H:%M";
              } # no %z / %s
              {
                type = "text";
                text = "prod";
              }
              {
                type = "command"; # last stdout line, /bin/sh -lc, on the server
                command = "~/.config/herdr/status.sh";
                interval_seconds = 5; # 1-31536000
                timeout_seconds = 2; # 1-3600
              }
            ];
            tab_bar_right_separator = " ";
            window_title = "{hostname}: {workspace}"; # {tab} {pane} {terminal_title}; "" leaves it alone
            agent_panel_sort = "spaces"; # spaces | priority
            status_indicators = "dots"; # dots | symbols
            accent = "cyan";
            sidebar.agents = {
              row_gap = 0;
              rows = [
                [
                  "state_icon"
                  "machine"
                  "workspace"
                  "tab"
                ]
                [ "agent" ]
              ];
              rows_by_agent = {
                pi = [
                  [
                    "state_icon"
                    "agent"
                    "state_text"
                  ]
                  [ "terminal_title_stripped" ]
                ];
              };
            };
            sidebar.spaces = {
              row_gap = 0;
              rows = [
                [
                  "state_icon"
                  "workspace"
                ]
                [
                  "branch"
                  "git_status"
                ]
              ];
            };
            toast = {
              delivery = "off"; # off | herdr | terminal | system
              delay_seconds = 1; # 0-3600
              herdr.position = "bottom-right"; # top-left top-right bottom-left bottom-right
              clipboard = {
                enabled = true;
                position = "top-center";
              };
            };
            sound = {
              enabled = true;
              path = "sounds/notification.mp3";
              done_path = "sounds/done.mp3";
              request_path = "sounds/request.mp3";
            };
          };
        };
      };
    };
}
