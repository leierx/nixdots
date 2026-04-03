{ config, inputs, ... }:
let
  user = config.flake.meta.user;
in
{
  flake.modules.nixos.homeManager =
    { lib, ... }:

    {
      config = {
        imports = [ inputs.home-manager.nixosModules.home-manager ];

        home-manager = {
          backupFileExtension = "backup";
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user.username} = {
            home = {
              username = lib.mkDefault user.username;
              homeDirectory = lib.mkDefault user.homeDirectory;
              stateVersion = lib.mkDefault inputs.home-manager.inputs.nixpkgs.lib.trivial.release;
            };
          };
        };
      };
    };
}
