{ flakeInputs }:
{
  hostName,
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
      {
        system.stateVersion = (flakeInputs.nixpkgs.lib.versions.majorMinor flakeInputs.nixpkgs.lib.version);
        networking.hostName = hostName;
        # import nixpkgs-unstable as an overlay
        nixpkgs.overlays = [
          (final: prev: {
            unstable = import flakeInputs.nixpkgs-unstable {
              inherit system;
              config = config.nixpkgs.config;
              overlays = config.nixpkgs.overlays;
            };
          })
        ];
      }
    )
  ];
}
