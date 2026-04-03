{ self, config, ... }:
let
  user = config.flake.meta.user;
in
{
  flake.modules.nixos.shell =
    { lib, pkgs, ... }:
    {
      config = {
        users.defaultUserShell = pkgs.bashInteractive;
        users.users.${user.username}.shell = lib.mkDefault pkgs.zsh;

        programs.zsh.enable = true;
        programs.starship.enable = true;

        home-manager.sharedModules = [ self.modules.homeManager.shell ];
      };
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
