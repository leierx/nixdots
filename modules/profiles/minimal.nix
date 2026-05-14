{ config, ... }:
let
  outerConfig = config;
in
{
  flake.modules.nixos.profileMinimal =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.dot.profile.minimal;
    in
    {
      options.dot.profile.minimal = {
        username = lib.mkOption {
          type = lib.types.singleLineStr;
          default = "leier";
          description = "Primary user account name";
        };
        fullName = lib.mkOption {
          type = lib.types.singleLineStr;
          default = "Lars Smith Eier";
          description = "Full name for the primary user";
        };
        email = lib.mkOption {
          type = lib.types.singleLineStr;
          default = "larssmitheier@protonmail.com";
          description = "Email for the primary user";
        };
      };

      imports = [
        outerConfig.flake.modules.nixos.bootloader
        outerConfig.flake.modules.nixos.basicPackages
        outerConfig.flake.modules.nixos.nixosConfig
        outerConfig.flake.modules.nixos.doas
        outerConfig.flake.modules.nixos.git
        outerConfig.flake.modules.nixos.journald
        outerConfig.flake.modules.nixos.locale
        outerConfig.flake.modules.nixos.root
        (outerConfig.flake.factories.nixos.user cfg.username)
        (outerConfig.flake.factories.nixos.homeManager cfg.username)
      ];

      config = {
        home-manager.users.${cfg.username}.imports = [
          outerConfig.flake.modules.homeManager.locale
          (outerConfig.flake.factories.homeManager.git {
            username = cfg.fullName;
            email = cfg.email;
          })
        ];
      };
    };
}
