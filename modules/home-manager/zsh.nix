{
  programs.zsh = {
    enable = true;
    history = {
      size = 10000;
      save = 690000;
    };
    autosuggestion = {
      enable = true;
      highlight = "fg=246";
    };
    oh-my-zsh.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
  };
}
