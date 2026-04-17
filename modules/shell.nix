{
  flake.factories.nixos.shell =
    username:
    { pkgs, ... }:
    {
      users.users.${username}.shell = pkgs.zsh;

      programs.zsh.enable = true;
      programs.starship.enable = true;
    };

  flake.modules.homeManager.shell = {
    programs.zsh = {
      enable = true;

      oh-my-zsh.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;

      history = {
        size = 10000;
        save = 690000;
      };

      autosuggestion = {
        enable = true;
        highlight = "fg=246";
      };

      initContent = ''
        # Accept autosuggestion with Ctrl+Space
        bindkey '^ ' autosuggest-execute
      '';
    };
  };
}
