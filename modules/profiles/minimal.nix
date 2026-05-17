{ config, ... }:
let
  outerConfig = config;
in
{
  flake.modules.nixos.minimal =
    { config, ... }:
    {
      imports = [
        outerConfig.flake.modules.nixos.profileOptions
        outerConfig.flake.modules.nixos.bootloader
        outerConfig.flake.modules.nixos.basePackages
        outerConfig.flake.modules.nixos.nixosConfig
        outerConfig.flake.modules.nixos.doas
        outerConfig.flake.modules.nixos.git
        outerConfig.flake.modules.nixos.homeManager
        outerConfig.flake.modules.nixos.journald
        outerConfig.flake.modules.nixos.locale
        outerConfig.flake.modules.nixos.network
        outerConfig.flake.modules.nixos.root
        outerConfig.flake.modules.nixos.user
        outerConfig.flake.modules.overlays.unstable
      ];

      config = {
        home-manager.users.${config.flakeModules.profile.user}.imports = [
          outerConfig.flake.modules.homeManager.git
          outerConfig.flake.modules.homeManager.locale
          outerConfig.flake.modules.homeManager.tmux
          outerConfig.flake.modules.homeManager.user
          outerConfig.flake.modules.homeManager.xdgUserDirs
        ];
      };
    };
}
