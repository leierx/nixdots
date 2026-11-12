root: {
  flake.modules.homeManager.tmux =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      c = root.config.palettes.adwaita_dark;
      paneLabel = "#{?#{==:#{pane_title},#{host}},#{pane_current_command} · #{b:pane_current_path},#{pane_title}}";
      tmux = lib.getExe pkgs.tmux;
      scrollback = pkgs.writeShellScript "tmux-scrollback" ''
        { ${tmux} save-buffer -b scrollback - && ${tmux} delete-buffer -b scrollback; } |
          ${lib.getExe config.programs.neovim.finalPackage} -R + -
      '';
      # resurrect saves every pi pane as `pi`; the pi-agent extension records each pane's session in @pi_session
      piSessions = pkgs.writeShellApplication {
        name = "tmux-resurrect-pi-sessions";
        runtimeInputs = [
          pkgs.tmux
          pkgs.gawk
        ];
        text = ''
          file=$1
          t=$'\t'
          tmux list-panes -a -F "#{session_name}$t#{window_index}$t#{pane_index}$t#{@pi_session}" |
            awk -F '\t' -v OFS='\t' -v q="'" '
              NR == FNR { if ($4 != "") session[$1, $2, $3] = $4; next }
              $1 == "pane" && $11 ~ /^:pi( |$)/ && ($2, $3, $6) in session {
                s = session[$2, $3, $6]; gsub(q, q "\\" q q, s); $11 = ":pi --session " q s q
              }
              { print }
            ' - "$file" > "$file.tmp"
          mv "$file.tmp" "$file"
        '';
      };
      paneMenu = lib.concatStringsSep " " [
        "display-menu -t= -xM -yM -T '#[align=centre]#{pane_index} (#{pane_id})'"
        "'#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Top,}' '<' { send -X history-top }"
        "'#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Bottom,}' '>' { send -X history-bottom }"
        "''"
        "'#{?#{&&:#{buffer_size},#{!:#{pane_in_mode}}},Paste,}' 'p' { paste-buffer }"
        "''"
        "'#{?mouse_word,Search For #[underscore]#{=/9/...:mouse_word},}' 'C-r' { if -F '#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}' 'copy-mode -t='; send -Xt= search-backward -- \"#{q:mouse_word}\" }"
        "'#{?mouse_word,Type #[underscore]#{=/9/...:mouse_word},}' 'C-y' { copy-mode -q; send-keys -l -- \"#{q:mouse_word}\" }"
        "'#{?mouse_word,Copy #[underscore]#{=/9/...:mouse_word},}' 'c' { copy-mode -q; set-buffer -- \"#{q:mouse_word}\" }"
        "'#{?mouse_line,Copy Line,}' 'l' { copy-mode -q; set-buffer -- \"#{q:mouse_line}\" }"
        "''"
        "'#{?mouse_hyperlink,Type #[underscore]#{=/9/...:mouse_hyperlink},}' 'C-h' { copy-mode -q; send-keys -l -- \"#{q:mouse_hyperlink}\" }"
        "'#{?mouse_hyperlink,Copy #[underscore]#{=/9/...:mouse_hyperlink},}' 'h' { copy-mode -q; set-buffer -- \"#{q:mouse_hyperlink}\" }"
        "''"
        "'New Window' 'w' { new-window -c '#{pane_current_path}' }"
        "'#{?#{!:#{pane_floating_flag}},Horizontal Split,}' 'h' { split-window -h }"
        "'#{?#{!:#{pane_floating_flag}},Vertical Split,}' 'v' { split-window -v }"
        "''"
        "'#{?#{&&:#{!:#{pane_floating_flag}},#{>:#{window_panes},1}},Swap Up,}' 'u' { swap-pane -U }"
        "'#{?#{&&:#{!:#{pane_floating_flag}},#{>:#{window_panes},1}},Swap Down,}' 'd' { swap-pane -D }"
        "'#{?pane_marked_set,,-}Swap Marked' 's' { swap-pane }"
        "''"
        "'Kill' 'X' { kill-pane }"
        "'Respawn' 'R' { respawn-pane -k }"
        "'#{?pane_marked,Unmark,Mark}' 'm' { select-pane -m }"
        "'#{?#{>:#{window_panes},1},,-}#{?window_zoomed_flag,Unzoom,Zoom}' 'z' { resize-pane -Z }"
      ];
      palette = pkgs.writeShellApplication {
        name = "tmux-command-palette";
        runtimeInputs = [
          pkgs.tmux
          pkgs.gawk
          pkgs.fzf
        ];
        text = ''
          t=$'\t'
          key=$(
            tmux list-keys -T prefix -F "#{key_string}$t#{key_note}$t#{key_command}" |
              awk -F '\t' '$2 != "" { printf "%s\t%-50s %s\t%s\n", $1, $2, $1, $3 }' |
              fzf --delimiter "$t" --with-nth 2 --reverse --no-info \
                --preview 'printf "%s\n" {3}' --preview-window down,3,wrap |
              cut -f1
          ) || exit 0
          tmux set -g @palette_key "$key"
        '';
      };
    in
    {
      programs.tmux = {
        enable = true;
        # a bare `tmux` attaches to the default session, creating it if needed
        package = pkgs.symlinkJoin {
          inherit (pkgs.tmux) pname version;
          paths = [
            pkgs.tmux
            pkgs.tmux.man
          ];
          meta.mainProgram = "tmux";
          postBuild = ''
            ln -sf ${pkgs.writeShellScript "tmux" ''
              if [ $# -eq 0 ]; then
                exec ${tmux} new-session -A -s main
              fi
              exec ${tmux} "$@"
            ''} $out/bin/tmux
          '';
        };
        terminal = "tmux-256color";
        baseIndex = 1;
        keyMode = "vi";
        mouse = true;
        escapeTime = 10;
        focusEvents = true;
        historyLimit = 50000;
        clock24 = true;

        extraConfig = ''
          # WezTerm's XTVERSION reply covers RGB and extkeys; OSC 8 needs declaring for its TERM
          set -as terminal-features "xterm-256color:hyperlinks"
          set -g extended-keys on
          set -g extended-keys-format csi-u

          set -g renumber-windows on
          set -g detach-on-destroy off
          set -g set-titles on
          set -g set-titles-string "#{host_short}: #S"
          set -g automatic-rename-format "#{?#{m/r:^(sh|bash|zsh|fish)$,#{pane_current_command}},#{b:pane_current_path},#{pane_current_command}}"
          set -g copy-mode-line-numbers hybrid

          # a bell from a background window marks it; prefix o jumps there
          set -g bell-action other

          unbind -a -T prefix
          bind -N "Send the prefix to the application" b send-prefix
          bind -N "Command palette" ? {
            set -gu @palette_key
            display-popup -E -w 70% -h 60% -T " commands " ${lib.getExe palette}
            if -F "#{@palette_key}" { run -C "switch-client -T prefix ; send -K '#{@palette_key}'" }
          }
          bind -N "Command prompt" : command-prompt
          bind -N "Detach" d detach-client
          bind -N "Reload the config" R { source-file "${config.xdg.configHome}/tmux/tmux.conf"; display-message "config reloaded" }

          bind -N "Go to any pane" f choose-tree -Z
          bind -N "Pick a session" F choose-tree -Zs
          bind -N "Grab words, paths and URLs from the window" / run-shell "${pkgs.tmuxPlugins.extrakto}/share/tmux-plugins/extrakto/scripts/open.sh '#{pane_id}'"
          bind -N "Next window with an alert" o next-window -a
          bind -N "New session" C command-prompt -p "session:" { new-session -s "%%" -c "#{pane_current_path}" }
          bind -N "Rename the session" W command-prompt -I "#S" { rename-session "%%" }
          bind -N "Kill the session" D confirm-before -p "kill session #S? (y/n)" kill-session
          bind -N "Previous session" P switch-client -p
          bind -N "Next session" N switch-client -n

          bind -N "New window" c new-window -c "#{pane_current_path}"
          bind -N "Rename the window" T command-prompt -I "#W" { rename-window "%%" }
          bind -N "Kill the window" X kill-window
          bind -N "Previous window" p previous-window
          bind -N "Next window" n next-window
          bind -N "Next window" C-b next-window
          ${lib.concatMapStringsSep "\n" (
            i: ''bind -N "Window ${toString i}" ${toString i} select-window -t :=${toString i}''
          ) (lib.range 1 9)}

          bind -N "Split side by side" v split-window -h -c "#{pane_current_path}"
          bind -N "Split stacked" s split-window -v -c "#{pane_current_path}"
          bind -N "Kill the pane" x kill-pane
          bind -N "Rename the pane" t command-prompt -I "#T" { select-pane -T "%%" }
          bind -N "Zoom the pane" m resize-pane -Z
          bind -N "Synchronize the window's panes" z set synchronize-panes
          bind -N "Clear the pane and its history" C-l { send-keys C-l; clear-history }
          bind -N "Copy mode" y copy-mode
          ${lib.optionalString config.programs.neovim.enable ''bind -N "The pane's scrollback in nvim" e { capture-pane -J -S - -b scrollback; display-popup -E -w 90% -h 90% -T " scrollback " ${scrollback} }''}
          bind -N "Next pane" Tab select-pane -t :.+
          bind -N "Pane left" h select-pane -L
          bind -N "Pane down" j select-pane -D
          bind -N "Pane up" k select-pane -U
          bind -N "Pane right" l select-pane -R
          bind -N "Swap with the pane left" H swap-pane -d -t "{left-of}"
          bind -N "Swap with the pane below" J swap-pane -d -t "{down-of}"
          bind -N "Swap with the pane above" K swap-pane -d -t "{up-of}"
          bind -N "Swap with the pane right" L swap-pane -d -t "{right-of}"
          bind -N "Resize mode: h/j/k/l, any other key leaves" r switch-client -T resize
          bind -T resize h { resize-pane -L 5; switch-client -T resize }
          bind -T resize j { resize-pane -D 5; switch-client -T resize }
          bind -T resize k { resize-pane -U 5; switch-client -T resize }
          bind -T resize l { resize-pane -R 5; switch-client -T resize }

          # wezterm's word boundary, so a double-click takes paths, URLs and flags whole
          set -g word-separators "\"'\`()[]{}<>|,;"
          bind -T copy-mode-vi v send -X begin-selection
          bind -T copy-mode-vi C-v send -X rectangle-toggle
          bind -T copy-mode-vi y send -X copy-selection-and-cancel
          bind -T copy-mode-vi Escape send -X cancel
          # upstream copies and drops back to the prompt; this keeps the scroll position and the highlight
          bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-no-clear
          # a click drops the kept selection, so the next drag starts a new one instead of extending a word/line pick
          bind -T copy-mode-vi MouseDown1Pane { select-pane; send -X clear-selection }
          bind -T copy-mode-vi MouseDown2Pane { select-pane; send -X copy-pipe-and-cancel }
          # upstream's pane menu, with a plain Paste label (its buffer preview shows newlines as \n) and a New Window entry
          bind -n MouseDown3Pane { if -Ft= '#{||:#{mouse_any_flag},#{&&:#{pane_in_mode},#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}}}' { select-pane -t=; send -M } { ${paneMenu} } }
          bind -n M-MouseDown3Pane { ${paneMenu} }

          set -g status-position top
          set -g status-justify left
          set -g status-style "bg=default,fg=${c.color7}"
          set -g status-left-length 40
          set -g status-left "#[fg=${c.foreground},bold] #S #[fg=${c.color8},nobold]│"
          set -g status-right "#{?client_prefix,#[fg=${c.color12}]prefix ,}#{?pane_in_mode,#[fg=${c.color3}]#{pane_mode} ,}"
          set -g window-status-separator ""
          set -g window-status-format " #I #W#{?window_bell_flag, #[fg=${c.color3}]●#[fg=${c.color7}],}#{?pane_synchronized, #[fg=${c.color3}]⇄#[fg=${c.color7}],}#{?window_zoomed_flag, #[fg=${c.color12}]⛶#[fg=${c.color7}],} "
          set -g window-status-current-style "fg=${c.foreground},bg=${c.color0}"
          set -g window-status-current-format " #[underscore]#I #W#{?pane_synchronized, #[fg=${c.color3}]⇄#[fg=${c.foreground}],}#{?window_zoomed_flag, #[fg=${c.color12}]⛶#[fg=${c.foreground}],}#[nounderscore] "
          set -g window-status-bell-style default
          set -g window-status-activity-style default

          set -g pane-border-status top
          set -g pane-border-format "#[align=right]#{?pane_active,#[fg=${c.foreground}],#[fg=${c.color8}]} ${paneLabel} "
          set -g pane-border-style "fg=${c.color8}"
          set -g pane-active-border-style "fg=#{?pane_synchronized,${c.color3},${c.color4}}"

          set -g popup-border-lines rounded
          set -g popup-border-style "fg=${c.color8}"
          set -g menu-style "fg=${c.foreground},bg=${c.background}"
          set -g menu-border-lines rounded
          set -g menu-border-style "fg=${c.color8}"
          set -g menu-selected-style "fg=${c.foreground},bg=${c.color4}"
          # fill blanks the bar under status-line prompts, as upstream's default does; pane and mode prompts stay unfilled
          set -g message-style 'fg=${c.foreground},bg=${c.background},#{?#{m/r:(^|#,)IS(PANE|MODE)($|#,),#{prompt_flags}},,fill=${c.background}}'
          set -g message-command-style 'fg=${c.foreground},bg=${c.background},#{?#{m/r:(^|#,)IS(PANE|MODE)($|#,),#{prompt_flags}},,fill=${c.background}}'
          set -g mode-style "fg=${c.selection_foreground},bg=${c.selection_background}"
          set -g copy-mode-match-style "fg=${c.foreground},bg=${c.color8}"
          set -g copy-mode-current-match-style "fg=${c.foreground},bg=${c.color4}"
          set -g copy-mode-line-number-style "fg=${c.color8}"
          set -g copy-mode-current-line-number-style "fg=${c.color7}"
          set -g display-panes-colour "${c.color8}"
          set -g display-panes-active-colour "${c.color4}"
          set -g clock-mode-colour "${c.color4}"

          # copy through tmux, which sets the terminal clipboard over OSC 52
          set -g @extrakto_clip_tool_run tmux_osc52

          # last, as TPM orders them: resurrect binds into the reset prefix table, continuum hooks the final status-right
          set -g @resurrect-capture-pane-contents on
          set -g @resurrect-processes 'pi'
          set -g @resurrect-hook-post-save-layout '${lib.getExe piSessions}'
          set -g @continuum-restore on
          run-shell ${pkgs.tmuxPlugins.resurrect.rtp}
          run-shell ${pkgs.tmuxPlugins.continuum.rtp}
        '';
      };
    };
}
