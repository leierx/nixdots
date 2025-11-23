{ flakeInputs }:
{ hostName, systemStateVersion, system ? "x86_64-linux" }:
let
  pkgsUnstable = import flakeInputs."nixpkgs-unstable" { inherit system; config.allowUnfree = true; };
in
flakeInputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit flakeInputs; inherit pkgsUnstable; };
  modules = [
    ../nixos-systems/${hostName}/configuration.nix

    flakeInputs.home-manager.nixosModules.home-manager
    flakeInputs.disko.nixosModules.disko

    {
      system.stateVersion = systemStateVersion;
      networking.hostName = hostName;
    }
  ];
}
