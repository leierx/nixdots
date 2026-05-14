{
  flake.modules.nixos.git.programs.git.enable = true;

  flake.factories.homeManager.git =
    { username, email }:
    {
      programs.git = {
        enable = true;
        settings = {
          user.name = username;
          user.email = email;
          credential.helper = "cache --timeout=36000";
          safe.directory = "*";
        };
      };
    };
}
