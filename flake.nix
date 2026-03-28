{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (import ./import-tree.nix inputs.nixpkgs.lib ./modules);

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # flake-parts
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # deterministic disk setup
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # hyprland
    hyprland = {
      url = "github:hyprwm/Hyprland?ref=v0.52.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprsplit = {
      url = "github:shezdy/hyprsplit?ref=v0.52.1";
      inputs.hyprland.follows = "hyprland";
    };
  };
}
