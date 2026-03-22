{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    targetFlake.url = "path:..";
  };

  outputs =
    {
      self,
      nixpkgs,
      targetFlake,
      ...
    }:
    let
      lib = nixpkgs.lib;

      mkInstaller =
        targetHost:
        lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit self targetFlake targetHost;
          };

          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ./config.nix
          ];
        };
    in
    {
      nixosConfigurations = lib.mapAttrs' (host: _: lib.nameValuePair "offlineInstaller-${host}" (mkInstaller host)) targetFlake.nixosConfigurations;
    };
}
