{
  flake.modules.homeManager.xdgUserDirs =
    { config, lib, ... }:
    {
      xdg = {
        enable = true;

        userDirs = {
          enable = true;
          createDirectories = true;

          desktop = "${config.home.homeDirectory}/Desktop";
          download = "${config.home.homeDirectory}/Downloads";
          music = "${config.home.homeDirectory}/Music";
          pictures = "${config.home.homeDirectory}/Pictures";
          videos = "${config.home.homeDirectory}/Videos";
          documents = "${config.home.homeDirectory}/Documents";
          publicShare = null;
        };
      };

      home.activation.createProjectsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/Projects"
      '';
    };
}
