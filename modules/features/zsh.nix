{
  flake.modules.homeManager.zsh =
    { lib, pkgs, ... }:
    let
      # fd honours .gitignore, which fzf's own walker does not
      fd = "${lib.getExe pkgs.fd} --hidden --exclude .git";
    in
    {
      # Ctrl-R history, Ctrl-T files, Alt-C directories
      programs.fzf = {
        enable = true;
        defaultCommand = "${fd} --type f";
        fileWidgetCommand = "${fd} --type f";
        changeDirWidgetCommand = "${fd} --type d";
      };

      programs.zsh = {
        enable = true;

        oh-my-zsh = {
          enable = true;
          # its audit of completion dirs finds only the read-only store
          extraConfig = "ZSH_DISABLE_COMPFIX=true";
        };
        syntaxHighlighting.enable = true;

        history = {
          size = 100000;
          extended = true;
          expireDuplicatesFirst = true;
          ignoreAllDups = true;
        };

        autosuggestion = {
          enable = true;
          highlight = "fg=246";
        };

        initContent = ''
          bindkey '^ ' autosuggest-execute
        '';
      };
    };
}
