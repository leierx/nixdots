# Home-manager itself: the NixOS and nix-darwin wiring that evaluates this
# host's home configuration for the primary user.
topLevel@{ inputs, lib, ... }:
let
  inherit (topLevel.config.identity) username;

  userModules = hostName: [
    { home.stateVersion = lib.mkDefault lib.trivial.release; }
    (topLevel.config.flake.modules.homeManager."homeConfigurations/${hostName}" or { })
  ];

  settings = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };
in
{
  flake.modules.nixos.home-manager =
    { config, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = settings // {
        users.${username}.imports = userModules config.networking.hostName;
      };
    };

  flake.modules.darwin.home-manager =
    { config, ... }:
    {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      # nix-darwin derives the home-manager home directory from this entry
      users.users.${username}.home = lib.mkDefault "/Users/${username}";

      home-manager = settings // {
        users.${username}.imports = userModules config.networking.hostName;
      };
    };
}
