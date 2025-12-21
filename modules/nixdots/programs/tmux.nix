{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.programs.tmux;
in
{
  options.nixdots.programs.tmux = {
    enable = lib.mkEnableOption "Enable tmux for the primary user";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${config.nixdots.core.primaryUser.username} = {
      home.packages = [ pkgs.tmux ];

      # ephemeral & per-user socket
      home.sessionVariables."TMUX_TMPDIR" = ''${XDG_RUNTIME_DIR: -"/run/user/$(id -u)"}'';

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
        bind-key -T prefix v split-window -h -c "#{pane_current_path}"
        bind-key -T prefix s split-window -v -c "#{pane_current_path}"

        # new window
        bind-key -T prefix c new-window -c "#{pane_current_path}"

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

        # detach
        bind-key -T prefix d detach-client

        # kill pane/window
        bind-key -T prefix x kill-pane
        bind-key -T prefix X kill-window

        # tree view
        bind-key -T prefix t choose-tree -Z

        # pane movement (prefix)
        bind-key -T prefix h select-pane -L
        bind-key -T prefix j select-pane -D
        bind-key -T prefix k select-pane -U
        bind-key -T prefix l select-pane -R

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
        bind-key -T prefix C-a next-window

        # tmux command prompt
        bind-key -T prefix : command-prompt

        # resize-mode trigger
        bind-key -T prefix r 'if-shell "[ #{window_panes} -gt 1 ]" "switch-client -T resize"'

        # resize-mode keys
        bind-key -T resize h resize-pane -L 5 \; switch-client -T resize
        bind-key -T resize j resize-pane -D 5 \; switch-client -T resize
        bind-key -T resize k resize-pane -U 5 \; switch-client -T resize
        bind-key -T resize l resize-pane -R 5 \; switch-client -T resize

        # enter copy-mode
        bind-key -T prefix p copy-mode

        bind-key -T copy-mode-vi h send-keys -X cursor-left
        bind-key -T copy-mode-vi j send-keys -X cursor-down
        bind-key -T copy-mode-vi k send-keys -X cursor-up
        bind-key -T copy-mode-vi l send-keys -X cursor-right

        # copy-mode scroll
        bind-key -T copy-mode-vi H send-keys -X top-line
        bind-key -T copy-mode-vi J send-keys -X scroll-down
        bind-key -T copy-mode-vi K send-keys -X scroll-up
        bind-key -T copy-mode-vi L send-keys -X bottom-line

        # copy + selection
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi Escape send-keys -X cancel

        # show status only when >1 window
        set -g status off
        run-shell -b 'tmux if-shell "[ #{session_windows} -gt 1 ]" "set status on"'
        set-hook -g window-linked  'if-shell "[ #{session_windows} -gt 1 ]" "set status on" ""'
        set-hook -g window-unlinked 'if-shell "[ #{session_windows} -le 1 ]" "set status off" ""'

        # Kanagawa palette
        set -g @kg_fg "#dcd7ba"
        set -g @kg_muted "#727169"
        set -g @kg_blue "#7e9cd8"
        set -g @kg_red "#e82424"
        set -g @kg_sel "#223249"

        set -g pane-border-style        "fg=#{@kg_muted},bg=default"
        set -g pane-active-border-style "fg=#{?pane_synchronized,#{@kg_red},#{@kg_blue}},bg=default"

        set -g message-style "fg=#{@kg_fg},bg=default"
        set -g message-command-style "fg=#{@kg_fg},bg=default"
        set -g mode-style "fg=#{@kg_fg},bg=#{@kg_sel}"

        set -g status-position top
        set -g status-justify centre
        set -g status-left ""
        set -g status-right ""
        set -g status-left-length 0
        set -g status-right-length 0

        set -g status-style "bg=default,fg=#{@kg_muted}"
        set -g window-status-separator "#[fg=#{@kg_muted}] • "

        set -g window-status-format "#[fg=#{@kg_muted}]#I #W#{?pane_synchronized, #[fg=#{@kg_red}]⇄#[fg=#{@kg_muted}],}#{?window_zoomed_flag, #[fg=#{@kg_blue}]⛶#[fg=#{@kg_muted}],}"
        set -g window-status-current-format "#[fg=#{@kg_fg}]#I #W#{?pane_synchronized, #[fg=#{@kg_red}]⇄#[fg=#{@kg_fg}],}#{?window_zoomed_flag, #[fg=#{@kg_blue}]⛶#[fg=#{@kg_fg}],}"
      '';
    };
  };
}
