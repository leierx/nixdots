{ nixpkgs }:
let
  linuxSystems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  darwinSystems = [
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  linuxPkgs = pkgs: {
    nixos-rollback-fzf = import ./bash-scripts/nixos-rollback-fzf { inherit pkgs; };
  };

  darwinPkgs = pkgs: { };
in
(nixpkgs.lib.genAttrs linuxSystems (system: linuxPkgs nixpkgs.legacyPackages.${system}))
# // (nixpkgs.lib.genAttrs darwinSystems (system: darwinPkgs nixpkgs.legacyPackages.${system}))
