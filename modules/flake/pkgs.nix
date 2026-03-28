{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;

        overlays = [
          (final: _prev: {
            unstable = import inputs.nixpkgs-unstable {
              inherit (final.stdenv.hostPlatform) system;
              config.allowUnfree = true;
            };
          })
        ];
      };
    };
}
