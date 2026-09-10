{
  modules.nixos.git.programs.git.enable = true;

  modules.home.git = { identity, ... }: {
    programs.git = {
      enable = true;
      settings = {
        user.name = identity.name;
        user.email = identity.email;
        credential.helper = "cache --timeout=36000";
        safe.directory = "*";
      };
    };
  };
}
