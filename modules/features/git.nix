top: {
  flake.modules.nixos.git.programs.git.enable = true;

  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      settings = {
        user.name = top.config.identity.fullName;
        user.email = top.config.identity.email;
        credential.helper = "cache --timeout=36000";
        safe.directory = "*";
      };
    };
  };
}
