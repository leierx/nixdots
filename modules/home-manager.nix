{ inputs, config, ... }:
let
  outerConfig = config;
in
{
  flake.modules.nixos.homeManager =
    { config, lib, ... }:
    let
      cfg = config.dot.homeManager;
    in
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      options.dot.homeManager = {
        user = lib.mkOption {
          type = lib.types.singleLineStr;
          default = outerConfig.flake.defaults.username;
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
