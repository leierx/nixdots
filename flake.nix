{
  description = "leier's NixOS / home-manager configurations";

  # Homemade flake-parts: every file under `modules/` is a module of one
  # top-level configuration, whose `flake` option set is the flake output.
  outputs =
    inputs:
    (inputs.nixpkgs.lib.evalModules {
      class = "flake";
      specialArgs.inputs = inputs;
      modules = [ (import ./import-tree.nix ./modules) ];
    }).config.flake;

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland/v0.56.1";
      # dev-only git hooks
      inputs.pre-commit-hooks.follows = "";
    };
    hyprsplit = {
      url = "github:shezdy/hyprsplit";
      inputs.hyprland.follows = "hyprland";
      # unused: hyprsplit builds with hyprland's nixpkgs
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };
  };
}
