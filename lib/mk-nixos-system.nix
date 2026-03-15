{ inputs }:
{
  hostName,
  system ? "x86_64-linux",
}:
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [
    ../hosts/${hostName}/configuration.nix
    (
      { config, ... }:
      {
        system.stateVersion = (inputs.nixpkgs.lib.versions.majorMinor inputs.nixpkgs.lib.version);
        networking.hostName = hostName;
        # import nixpkgs-unstable as an overlay
        nixpkgs.overlays = [
          (final: prev: {
            unstable = import inputs.nixpkgs-unstable {
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
