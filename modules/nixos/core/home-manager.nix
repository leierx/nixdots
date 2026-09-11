# Home-manager, evaluated inside the NixOS configuration of each host.
#
# The `topLevel` argument is the top-level configuration, which is how a
# lower-level module reaches the dendritic registry without `specialArgs`.
topLevel@{ inputs, ... }:
{
  flake.modules.nixos.home-manager =
    { config, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

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
