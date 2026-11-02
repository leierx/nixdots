{
  flake.modules.homeManager.xdg-user-dirs = {
    xdg = {
      enable = true;

      userDirs = {
        enable = true;
        createDirectories = true;
        publicShare = null;
      };
    };
  };
}
