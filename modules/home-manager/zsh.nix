{
  programs.zsh = {
    enable = true;

    # oh-my-zsh
    oh-my-zsh.enable = true;

    # Additional completion definitions
    enableCompletion = true;

    # fish shell-like syntax highlighting
    syntaxHighlighting.enable = true;

    # history settings
    history = {
      size = 10000;
      save = 690000;
    };

    # fish-like autosuggestions
    autosuggestion = {
      enable = true;
      highlight = "fg=246";
    };

    initContent = ''
      # Accept autosuggestion with Ctrl+Space
      bindkey '^ ' autosuggest-execute
    '';
  };
}
