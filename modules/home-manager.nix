{ inputs, ... }:
{
  flake.modules.nixos.homeManager =
    { config, lib, ... }:
    let
      cfg = config.flakeModules.homeManager;
    in
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      options.flakeModules.homeManager = {
        user = lib.mkOption {
          type = lib.types.singleLineStr;
          default = "leier";
          description = "User to set up home-manager for";
        };
      };

      config = {
        home-manager = {
          backupFileExtension = "backup";
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${cfg.user}.home = {
            username = cfg.user;
            homeDirectory = lib.mkDefault "/home/${cfg.user}";
            stateVersion = lib.mkDefault (inputs.home-manager.inputs.nixpkgs.lib.trivial.release);
          };
        };
      };
    };
}
