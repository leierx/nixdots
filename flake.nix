{
  description = "leier's NixOS / nix-darwin / home-manager configurations";

  # Homemade flake-parts: every file under `modules/` is a module of one
  # top-level configuration, whose `flake` option set is the flake output.
  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;

      # `extra` is how an external flake joins this evaluation instead of
      # consuming its frozen result: its modules are merged in before any
      # option resolves, so every value read as `root.config.<option>` is
      # theirs to define.
      eval =
        extra:
        (lib.evalModules {
          class = "flake";
          specialArgs.inputs = inputs;
          modules = [ (import ./import-tree.nix ./modules) ] ++ lib.toList extra;
        }).config.flake;
    in
    eval [ ]
    // {
      # not part of the evaluation, it *is* the evaluation
      lib.reconfigure = eval;
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
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

    hyprland.url = "github:hyprwm/Hyprland/v0.56.1";
    hyprsplit = {
      url = "github:shezdy/hyprsplit";
      inputs.hyprland.follows = "hyprland";
    };
  };
}
