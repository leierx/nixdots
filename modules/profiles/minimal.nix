{ config, ... }:
let
  outerConfig = config;
in
{
  modules.nixos.profiles.minimal =
    { config, lib, ... }:
    let
      cfg = config.profileConfig.minimal;
    in
    {
      options.profileConfig.minimal.user = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "leier";
      };

      imports = [
        (outerConfig.modules.nixos.factories.homeManager cfg.user)
        outerConfig.modules.nixos.bootloader
        outerConfig.modules.nixos.basePackages
        outerConfig.modules.nixos.nixosConfig
        outerConfig.modules.nixos.doas
        outerConfig.modules.nixos.git
        outerConfig.modules.nixos.journald
        outerConfig.modules.nixos.locale
        outerConfig.modules.nixos.network
        outerConfig.modules.nixos.root
        outerConfig.modules.nixos.user
        outerConfig.modules.overlays.unstableNixpkgs
      ];

      config = {
        home-manager.users.${cfg.user}.imports = [
          outerConfig.modules.homeManager.git
          outerConfig.modules.homeManager.locale
          outerConfig.modules.homeManager.tmux
          outerConfig.modules.homeManager.user
          outerConfig.modules.homeManager.xdgUserDirs
        ];
      };
    };
}
