# Home-manager, evaluated inside the nix-darwin configuration of each host.
topLevel@{ inputs, ... }:
{
  flake.modules.darwin.home-manager =
    { config, lib, ... }:
    {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      # nix-darwin derives the home-manager home directory from this entry
      users.users.leier.home = lib.mkDefault "/Users/leier";

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        users.leier.imports = [
          topLevel.config.flake.modules.homeManager.core
          (topLevel.config.flake.modules.homeManager."homeConfigurations/${config.networking.hostName}" or { }
          )
        ];
      };
    };
}
