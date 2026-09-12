{ inputs, ... }:
{
  flake.modules.nixos.core.nixpkgs.config.allowUnfree = true;

  flake.modules.nixos.unstable-nixpkgs =
    { config, pkgs, ... }:
    {
      nixpkgs.overlays = [
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (pkgs.stdenv.hostPlatform) system;
            inherit (config.nixpkgs) config;
          };
        })
      ];
    };
}
