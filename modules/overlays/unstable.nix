{ inputs, ... }:
{
  flake.modules.overlays.unstable =
    { config, pkgs, ... }:
    {
      nixpkgs.overlays = [
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (pkgs.stdenv.hostPlatform) system;
            inherit (config.nixpkgs) config;
            overlays = config.nixpkgs.overlays;
          };
        })
      ];
    };
}
