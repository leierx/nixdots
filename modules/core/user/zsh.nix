{ config, pkgs, lib, ... }:
let
  cfg = config.dots.core.user;
in
{
  config = lib.mkIf (cfg.shell == "zsh") {
    users.users.${cfg.name}.shell = pkgs.zsh;

    programs.zsh = {
      enable = true;
      ohMyZsh.enable = true;
      #ohMyZsh.custom = ''
      #  # Accept fish-style autosuggestion with Ctrl-Space
      #  bindkey '^ ' autosuggest-accept
      #'';
      enableCompletion = true;
      autosuggestions.enable = true;
      autosuggestions.highlightStyle = "fg=246";
      syntaxHighlighting.enable = true;
      histSize = 10000;
    };

    home-manager.sharedModules = [
      {
        programs.zsh = {
          enable = true;
          history.save = 690000;
        };
      }
    ];
  };
}
