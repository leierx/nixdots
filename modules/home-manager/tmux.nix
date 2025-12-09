{ pkgs, ... }:
{
  home.packages = [ pkgs.tmux ];

  # ephemeral & per-user socket
  home.sessionVariables."TMUX_TMPDIR" = ''''${XDG_RUNTIME_DIR:-"/run/user/$(id -u)"}'';

  # autostart tmux
  programs.zsh.initContent = ''if [[ -z "$TMUX" ]]; then tmux new-session -A -s "win-$$"; fi'';
  programs.bash.initExtra = ''if [[ -z "$TMUX" ]]; then tmux new-session -A -s "win-$$"; fi'';

  xdg.configFile."tmux/tmux.conf".text = ''
    # remove default keybindings
    unbind-key -a
    unbind-key -a -T copy-mode

    # faster esc + editor focus support
    set -sg escape-time 10
    set -g focus-events on

    # move window left/right
    bind-key -T prefix < swap-window -t -1
    bind-key -T prefix > swap-window -t +1

    # terminal + truecolor
    set -g default-terminal "screen-256color"
    set -ag terminal-overrides ",xterm-256color:Tc"

    # mouse disabled
    set -g mouse off

    # large history
    set -g history-limit 500000

    # indexes start at 1
    set -g base-index 1
    setw -g pane-base-index 1

    # vi-style keys
    set -g status-keys vi
    set -g mode-keys vi

    # prefix key
    set -g prefix C-a
    bind-key C-a send-prefix

    # splits
    bind-key -T prefix v split-window -h
    bind-key -T prefix s split-window -v

    # new window
    bind-key -T prefix c new-window

    # reload config
    bind-key -T prefix R \
      source-file "$XDG_CONFIG_HOME/tmux/tmux.conf" \; \
      display-message "Config reloaded"

    # sync panes
    bind-key -T prefix y set-window-option synchronize-panes

    # zoom pane
    bind-key -T prefix m resize-pane -Z

    # better resizing
    setw -g aggressive-resize on

    # auto renumber
    set -g renumber-windows on

    # no auto rename
    setw -g allow-rename off
    setw -g automatic-rename off
    set-hook -g after-new-window 'rename-window ""'
    set-hook -g session-created 'rename-window ""'
    bind-key , command-prompt "rename-window '%%'"

    # detach
    bind-key -T prefix d detach-client

    # kill pane/window
    bind-key -T prefix x kill-pane
    bind-key -T prefix X kill-window

    # tree view
    bind-key -T prefix t choose-tree -Z

    # pane movement (prefix)
    bind-key -T prefix j select-pane -L
    bind-key -T prefix k select-pane -D
    bind-key -T prefix l select-pane -U
    bind-key -T prefix ø select-pane -R

    # pane movement (alt)
    bind-key -n M-j select-pane -L
    bind-key -n M-k select-pane -D
    bind-key -n M-l select-pane -U
    bind-key -n M-\; select-pane -R
    bind-key -n M-c select-pane -t :.+

    # jump to window
    bind-key -T prefix 0 select-window -t 0
    bind-key -T prefix 1 select-window -t 1
    bind-key -T prefix 2 select-window -t 2
    bind-key -T prefix 3 select-window -t 3
    bind-key -T prefix 4 select-window -t 4
    bind-key -T prefix 5 select-window -t 5
    bind-key -T prefix 6 select-window -t 6
    bind-key -T prefix 7 select-window -t 7
    bind-key -T prefix 8 select-window -t 8
    bind-key -T prefix 9 select-window -t 9

    # window movement (alt)
    bind-key -n M-J previous-window
    bind-key -n M-: next-window
    bind-key -n M-C last-window
    bind-key -T prefix C-a last-window

    # tmux command prompt
    bind-key -T prefix : command-prompt

    # resize-mode trigger
    bind-key -T prefix r 'if-shell "[ #{window_panes} -gt 1 ]" "switch-client -T resize"'

    # resize-mode keys
    bind-key -T resize j resize-pane -L 5 \; switch-client -T resize
    bind-key -T resize k resize-pane -D 5 \; switch-client -T resize
    bind-key -T resize l resize-pane -U 5 \; switch-client -T resize
    bind-key -T resize ø resize-pane -R 5 \; switch-client -T resize
    bind-key -T resize Space select-layout tiled
    bind-key -T resize Escape switch-client -T prefix

    # enter copy-mode
    bind-key -T prefix p copy-mode

    # remove unwanted vi binds
    unbind-key -T copy-mode-vi h
    unbind-key -T copy-mode-vi H

    # copy-mode movement
    bind-key -T copy-mode-vi j send-keys -X cursor-left
    bind-key -T copy-mode-vi k send-keys -X cursor-down
    bind-key -T copy-mode-vi l send-keys -X cursor-up
    bind-key -T copy-mode-vi ø send-keys -X cursor-right

    # copy-mode scroll
    bind-key -T copy-mode-vi J send-keys -X top-line
    bind-key -T copy-mode-vi K send-keys -X scroll-down
    bind-key -T copy-mode-vi L send-keys -X scroll-up
    bind-key -T copy-mode-vi Ø send-keys -X bottom-line

    # copy + selection
    bind-key -T copy-mode-vi v send-keys -X begin-selection
    bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
    bind-key -T copy-mode-vi Escape send-keys -X cancel

    # status styling
    set -g status-style "bg=default,fg=#6C7086"
    set -g status-position top
    set -g status-left ""
    set -g status-right "%H:%M"

    # window style
    set -g window-status-format "#[bg=#313244,fg=#6C7086] #{window_index}#{?#{!=:#{window_name},}, #{window_name},}#{?pane_synchronized, ↻,}#{?window_zoomed_flag, ⬚,} #[default]"
    set -g window-status-current-format "#[bg=#45475a,fg=#ffffff,bold] #{window_index}#{?#{!=:#{window_name},}, #{window_name},}#{?pane_synchronized, ↻,}#{?window_zoomed_flag, ⬚,} #[default]"
    set -g window-status-separator " "

    # show status only when >1 window
    if-shell "[ #{session_windows} -gt 1 ]" "set -g status on" "set -g status off"
    set-hook -g window-linked  'if-shell "[ #{session_windows} -gt 1 ]" "set -g status on" ""'
    set-hook -g window-unlinked 'if-shell "[ #{session_windows} -le 1 ]" "set -g status off" ""'
  '';
}
