# Home-manager, evaluated inside the nix-darwin configuration of each host.
topLevel@{ inputs, ... }:
let
  inherit (topLevel.config.identity) username;
in
{
  flake.modules.darwin.home-manager =
    { config, lib, ... }:
    {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      # nix-darwin derives the home-manager home directory from this entry
      users.users.${username}.home = lib.mkDefault "/Users/${username}";

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        users.${username}.imports = [
          topLevel.config.flake.modules.homeManager.core
          (topLevel.config.flake.modules.homeManager."homeConfigurations/${config.networking.hostName}" or { }
          )
        ];
      };
    };
}
