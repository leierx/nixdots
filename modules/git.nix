{ self, config, ... }:
let
  user = config.flake.meta.user;
in
{
  flake.modules.nixos.git = {
    config = {
      programs.git.enable = true;
      home-manager.sharedModules = [ self.modules.homeManager.git ];
    };
  };

  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      settings = {
        user.name = user.fullName;
        user.email = user.email;
        credential.helper = "cache --timeout=36000";
        safe.directory = "*";
      };
    };
  };
}
