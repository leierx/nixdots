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

          # T3 Code's dark colours, with the chrome kept darker than wezterm's pane background
          theme = {
            name = "vesper";
            custom = {
              accent = "#346bf1";
              panel_bg = "#111113";
              sidebar_bg = "#111113";
              active_row_bg = "#232327";
              selection_bg = "#2d3340";
              surface0 = "#232327";
              surface1 = "#2e2e33";
              surface_dim = "#18181b";
              overlay0 = "#52525b";
              overlay1 = "#8f8f8f";
              text = "#f3f3f4";
              subtext0 = "#a1a1a1";
              mauve = "#a1a1a1";
              green = "#0dbc79";
              yellow = "#346bf1"; # working
              red = "#fe9a00"; # blocked
              blue = "#f5f5f5"; # done
              teal = "#29b8db";
              peach = "#fe9a00";
            };
          };

          update = {
            version_check = false;
          };

          keys = {
            prefix = "ctrl+b";
            help = "prefix+?";
            settings = ""; # config.toml is a read-only store link
            detach = "prefix+d";
            reload_config = "prefix+shift+r";
            open_notification_target = "prefix+o";
            workspace_picker = "prefix+w";
            goto = "prefix+f"; # every pane by workspace; / searches, b/w/i/d filter by state
            new_workspace = "prefix+shift+n";
            new_worktree = "prefix+shift+g";
            open_worktree = "prefix+shift+o";
            remove_worktree = ""; # unset; asks for confirmation
            rename_workspace = "prefix+shift+w";
            close_workspace = "prefix+shift+d";
            previous_workspace = "prefix+ctrl+k";
            next_workspace = "prefix+ctrl+j";
            switch_workspace = "prefix+alt+1..9"; # shift+digits are layout symbols on no
            previous_agent = ""; # unset
            next_agent = ""; # unset
            focus_agent = ""; # unset
            remote_image_paste = "ctrl+v"; # herdr --remote only; "" disables
            new_tab = "prefix+c";
            rename_tab = "prefix+shift+t";
            previous_tab = "prefix+p";
            next_tab = "prefix+n";
            move_tab_previous = "prefix+<";
            move_tab_next = "prefix+>";
            switch_tab = "prefix+1..9";
            close_tab = "prefix+shift+x";
            rename_pane = "prefix+shift+p";
            edit_scrollback = "prefix+e"; # opens scrollback in $EDITOR
            clear_pane = "prefix+ctrl+l";
            copy_mode = "prefix+y"; # "[" needs AltGr on the no layout
            focus_pane_left = "prefix+h";
            focus_pane_down = "prefix+j";
            focus_pane_up = "prefix+k";
            focus_pane_right = "prefix+l";
            swap_pane_left = "prefix+shift+h";
            swap_pane_down = "prefix+shift+j";
            swap_pane_up = "prefix+shift+k";
            swap_pane_right = "prefix+shift+l";
            resize_pane_left = "prefix+alt+h";
            resize_pane_down = "prefix+alt+j";
            resize_pane_up = "prefix+alt+k";
            resize_pane_right = "prefix+alt+l";
            cycle_pane_next = "prefix+tab";
            cycle_pane_previous = "prefix+shift+tab";
            last_pane = "prefix+a"; # across workspaces and tabs
            split_vertical = "prefix+v"; # side by side, as vim's :vsplit
            split_horizontal = "prefix+s"; # stacked, as vim's :split
            close_pane = "prefix+x";
            zoom = "prefix+m";
            resize_mode = "prefix+r"; # h/j/k/l resize; esc, enter or prefix+r leaves
            toggle_sidebar = "prefix+b";
            navigate_workspace_up = "k";
            navigate_workspace_down = "j";
            navigate_pane_left = "h";
            navigate_pane_down = "shift+j";
            navigate_pane_up = "shift+k";
            navigate_pane_right = "l";
          };

          ui = {
            sidebar_start_collapsed = false;
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
            pane_borders = "always"; # every pane a framed card, a lone one too
            pane_outer_borders = true;
            pane_scrollbars = false;
            pane_gaps = true;
            show_agent_labels_on_pane_borders = false;
            hide_tab_bar_when_single_tab = false;
            tab_bar_position = "top"; # top | bottom
            tab_bar_right = [ { type = "zoom"; } ];
            window_title = "{hostname}: {workspace}"; # {tab} {pane} {terminal_title}; "" leaves it alone
            agent_panel_sort = "spaces"; # spaces | priority
            status_indicators = "dots"; # dots | symbols
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
              row_gap = 1;
              rows = [
                [
                  "state_icon"
                  {
                    token = "workspace";
                    bold = true;
                  }
                ]
                [
                  {
                    token = "branch";
                    dim = true;
                  }
                  {
                    token = "git_status";
                    dim = true;
                  }
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
            sound.enabled = true;
          };
        };
      };
    };
}
