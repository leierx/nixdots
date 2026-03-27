{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    # nixpkgs
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-25.11";
    };
    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
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
    # https://github.com/vic/import-tree/commit/c41e7d58045f9057880b0d85e1152d6a4430dbf1
    import-tree.url = "path:./import-tree";
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
