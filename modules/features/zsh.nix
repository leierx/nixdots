{
  flake.modules.homeManager.zsh = {
    # Ctrl-R history, Ctrl-T files, Alt-C directories
    programs.fzf.enable = true;

    programs.zsh = {
      enable = true;

      oh-my-zsh.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;

      history.size = 100000;

      autosuggestion = {
        enable = true;
        highlight = "fg=246";
      };

      initContent = ''
        # Execute autosuggestion with Ctrl+Space
        bindkey '^ ' autosuggest-execute
      '';
    };
  };
}
