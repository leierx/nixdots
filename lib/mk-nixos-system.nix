{ inputs }:
{
  hostName,
  system ? "x86_64-linux",
}:
let
  nixpkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
    };
    overlays = [
      (final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config = final.config;
          overlays = final.overlays;
        };
      })
    ];
  };
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [
    ../hosts/${hostName}/configuration.nix
    {
      system.stateVersion = (inputs.nixpkgs.lib.versions.majorMinor inputs.nixpkgs.lib.version);
      networking.hostName = hostName;
    }
  ];
}
