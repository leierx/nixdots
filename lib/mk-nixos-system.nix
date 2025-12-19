{ flakeInputs }:
{
  hostName,
  systemStateVersion,
  system ? "x86_64-linux",
}:
flakeInputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit flakeInputs; };
  modules = [
    ../nixos-systems/${hostName}/configuration.nix

    flakeInputs.home-manager.nixosModules.home-manager
    flakeInputs.disko.nixosModules.disko

    (
      { config, pkgs, ... }:
      let
        unstableOverlay = final: prev: {
          unstable = import flakeInputs.nixpkgs-unstable {
            inherit system;
            config = config.nixpkgs.config;
            overlays = config.nixpkgs.overlays;
          };
        };
      in
      {
        system.stateVersion = systemStateVersion;
        networking.hostName = hostName;
        nixpkgs.overlays = [ unstableOverlay ];
      }
    )
  ];
}
