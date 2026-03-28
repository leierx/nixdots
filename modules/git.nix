{ config, self, ... }:
{
  flake.modules.nixos.git = {
    programs.git.enable = true;

    home-manager.users.${config.flake.settings.user.username}.imports = [ self.modules.homeManager.git ];
  };

  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = config.flake.settings.user.fullName;
          email = config.flake.settings.user.email;
        };
        credential.helper = "cache --timeout=36000";
        safe.directory = "*";
      };
    };
  };
}
