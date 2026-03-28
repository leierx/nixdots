{ self, config, ... }:
{
  flake.modules.nixos.zsh =
    { pkgs, ... }:
    {
      users.defaultUserShell = pkgs.bashInteractive;

      programs.zsh.enable = true;
      programs.starship.enable = true;

      home-manager.users.${config.flake.settings.user.username}.imports = [
        self.flake.modules.homeManager.zsh
      ];
    };

  flake.modules.homeManager.zsh = {
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
