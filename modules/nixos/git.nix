{ config, self, ... }:
{
  flake.modules.nixos.git = {
    programs.git.enable = true;

    home-manager.users.${config.flake.settings.user.username}.imports = [ self.modules.homeManager.git ];
  };
}
