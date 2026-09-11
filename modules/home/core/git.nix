top: {
  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      settings = {
        user.name = top.config.me.fullName;
        user.email = top.config.me.email;
        credential.helper = "cache --timeout=36000";
        safe.directory = "*";
      };
    };
  };
}
