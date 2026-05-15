{ config, ... }:
let
  outerConfig = config;
in
{
  flake.modules.nixos.shell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dot.shell;
    in
    {
      options.dot.shell = {
        user = lib.mkOption {
          type = lib.types.singleLineStr;
          default = outerConfig.flake.defaults.username;
          description = "User to set zsh as login shell for";
        };
      };

      config = {
        users.users.${cfg.user}.shell = pkgs.zsh;

        programs.zsh.enable = true;
        programs.starship.enable = true;
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
