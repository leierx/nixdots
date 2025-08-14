{ flakeInputs }:
{ hostName, systemStateVersion, system ? "x86_64-linux", useGlobalModules ? true }:
let
  nixpkgs = flakeInputs.nixpkgs;
  pkgsUnstable = import flakeInputs."nixpkgs-unstable" { inherit system; config.allowUnfree = true; };
  lib = nixpkgs.lib;
  configuration = ../systems/${hostName}/configuration.nix;
  hardwareConfiguration = ../systems/${hostName}/hardware.nix;
  monitorConfiguration = ../systems/${hostName}/monitors.nix;
  globalModules = ../modules;
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit flakeInputs; inherit pkgsUnstable; };
  modules = [
    configuration
    hardwareConfiguration
    flakeInputs.home-manager.nixosModules.home-manager
    {
      system.stateVersion = systemStateVersion;
      networking.hostName = hostName;
    }
  ]
    ++ lib.optionals (builtins.pathExists monitorConfiguration) [ monitorConfiguration ]
    ++ lib.optionals useGlobalModules [ globalModules ];
}
