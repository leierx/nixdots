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
    in
    {
      programs.tmux = {
        enable = true;
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
          bind -N "Send the prefix to the application" C-b send-prefix
          bind -N "List key bindings" ? list-keys -N
          bind -N "Command prompt" : command-prompt
          bind -N "Detach" d detach-client
          bind -N "Reload the config" R { source-file "${config.xdg.configHome}/tmux/tmux.conf"; display-message "config reloaded" }
          bind -N "Toggle the status bar" b if -F "#{==:#{status},on}" { set status off } { set status on }

          bind -N "Go to any pane" f choose-tree -Z
          bind -N "Pick a session" w choose-tree -Zs
          bind -N "Next window with an alert" o next-window -a
          bind -N "New session" N command-prompt -p "session:" { new-session -s "%%" -c "#{pane_current_path}" }
          bind -N "Rename the session" W command-prompt -I "#S" { rename-session "%%" }
          bind -N "Kill the session" D confirm-before -p "kill session #S? (y/n)" kill-session
          bind -N "Previous session" C-k switch-client -p
          bind -N "Next session" C-j switch-client -n

          bind -N "New window, prompting for a name (esc keeps auto-naming)" c { new-window -c "#{pane_current_path}"; command-prompt -p "window:" { rename-window "%%" } }
          bind -N "Rename the window" T command-prompt -I "#W" { rename-window "%%" }
          bind -N "Kill the window" X kill-window
          bind -N "Previous window" p previous-window
          bind -N "Next window" n next-window
          bind -N "Last window" a last-window
          bind -N "Move the window left" < swap-window -t -1
          bind -N "Move the window right" > swap-window -t +1
          ${lib.concatMapStringsSep "\n" (
            i: ''bind -N "Window ${toString i}" ${toString i} select-window -t :=${toString i}''
          ) (lib.range 1 9)}

          bind -N "Split side by side" v split-window -h -c "#{pane_current_path}"
          bind -N "Split stacked" s split-window -v -c "#{pane_current_path}"
          bind -N "Kill the pane" x kill-pane
          bind -N "Rename the pane" P command-prompt -I "#T" { select-pane -T "%%" }
          bind -N "Zoom the pane" m resize-pane -Z
          bind -N "Synchronize the window's panes" S set synchronize-panes
          bind -N "Clear the pane and its history" C-l { send-keys C-l; clear-history }
          bind -N "Copy mode" y copy-mode
          bind -N "Next pane" Tab select-pane -t :.+
          bind -N "Previous pane" BTab select-pane -t :.-
          bind -N "Pane left" h select-pane -L
          bind -N "Pane down" j select-pane -D
          bind -N "Pane up" k select-pane -U
          bind -N "Pane right" l select-pane -R
          bind -N "Swap with the pane left" H swap-pane -d -t "{left-of}"
          bind -N "Swap with the pane below" J swap-pane -d -t "{down-of}"
          bind -N "Swap with the pane above" K swap-pane -d -t "{up-of}"
          bind -N "Swap with the pane right" L swap-pane -d -t "{right-of}"
          bind -N "Resize left" -r M-h resize-pane -L 5
          bind -N "Resize down" -r M-j resize-pane -D 5
          bind -N "Resize up" -r M-k resize-pane -U 5
          bind -N "Resize right" -r M-l resize-pane -R 5
          bind -N "Resize mode: h/j/k/l, any other key leaves" r switch-client -T resize
          bind -T resize h { resize-pane -L 5; switch-client -T resize }
          bind -T resize j { resize-pane -D 5; switch-client -T resize }
          bind -T resize k { resize-pane -U 5; switch-client -T resize }
          bind -T resize l { resize-pane -R 5; switch-client -T resize }

          bind -T copy-mode-vi v send -X begin-selection
          bind -T copy-mode-vi C-v send -X rectangle-toggle
          bind -T copy-mode-vi y send -X copy-selection-and-cancel
          bind -T copy-mode-vi Escape send -X cancel
          # upstream copies and drops back to the prompt; this keeps the scroll position and the highlight
          bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-no-clear

          set -g status-position top
          set -g status-justify left
          set -g status-style "bg=default,fg=${c.color7}"
          set -g status-left-length 40
          set -g status-left "#[fg=${c.foreground},bold] #S #[fg=${c.color8},nobold]│"
          set -g status-right "#{?client_prefix,#[fg=${c.color12}]prefix ,}#{?pane_in_mode,#[fg=${c.color3}]#{pane_mode} ,}#[fg=${c.color8}]#{host_short} "
          set -g window-status-separator ""
          set -g window-status-format " #I #W#{?window_bell_flag, #[fg=${c.color3}]●,}#{?pane_synchronized, #[fg=${c.color3}]⇄,}#{?window_zoomed_flag, #[fg=${c.color12}]⛶,} "
          set -g window-status-current-format "#[fg=${c.foreground},bg=${c.color0}] #I #W#{?pane_synchronized, #[fg=${c.color3}]⇄,}#{?window_zoomed_flag, #[fg=${c.color12}]⛶,} "
          set -g window-status-bell-style default
          set -g window-status-activity-style default

          set -g pane-border-status top
          set -g pane-border-format "#{?pane_active,#[fg=${c.foreground}],#[fg=${c.color8}]} #{?#{==:#{pane_title},#{host}},#{pane_current_command} · #{b:pane_current_path},#{pane_title}} "
          set -g pane-border-style "fg=${c.color8}"
          set -g pane-active-border-style "fg=#{?pane_synchronized,${c.color3},${c.color4}}"

          set -g popup-border-lines rounded
          set -g popup-border-style "fg=${c.color8}"
          set -g menu-style "fg=${c.foreground},bg=${c.background}"
          set -g menu-border-lines rounded
          set -g menu-border-style "fg=${c.color8}"
          set -g menu-selected-style "fg=${c.foreground},bg=${c.color4}"
          set -g message-style "fg=${c.foreground},bg=${c.color0}"
          set -g message-command-style "fg=${c.foreground},bg=${c.color0}"
          set -g mode-style "fg=${c.selection_foreground},bg=${c.selection_background}"
          set -g copy-mode-match-style "fg=${c.foreground},bg=${c.color8}"
          set -g copy-mode-current-match-style "fg=${c.foreground},bg=${c.color4}"
          set -g copy-mode-line-number-style "fg=${c.color8}"
          set -g copy-mode-current-line-number-style "fg=${c.color7}"
          set -g display-panes-colour "${c.color8}"
          set -g display-panes-active-colour "${c.color4}"
          set -g clock-mode-colour "${c.color4}"

          # last, as TPM orders them: resurrect binds into the reset prefix table, continuum hooks the final status-right
          set -g @resurrect-capture-pane-contents on
          set -g @continuum-restore on
          run-shell ${pkgs.tmuxPlugins.resurrect.rtp}
          run-shell ${pkgs.tmuxPlugins.continuum.rtp}
        '';
      };
    };
}
