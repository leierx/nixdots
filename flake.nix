{
  outputs =
    inputs:
    (inputs.nixpkgs.lib.evalModules {
      specialArgs.inputs = inputs;
      modules = [ (import ./import-tree.nix ./modules) ];
    }).config;

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # deterministic disk setup
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Hyprland v0.55.2
    hyprland = {
      url = "github:hyprwm/Hyprland/v0.55.2";
    };
    hyprsplit = {
      url = "github:shezdy/hyprsplit/v0.54.3";
      inputs.hyprland.follows = "hyprland";
    };
  };
}
