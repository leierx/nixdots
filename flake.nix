{
  outputs = { nixpkgs, home-manager, ... }@flakeInputs:
    let
      mkNixosSystem = (import ./lib/mk-nixos-system.nix { inherit flakeInputs; });
    in
      {
        nixosConfigurations = {
          desktop = mkNixosSystem { hostName = "desktop"; systemStateVersion = "25.11"; };
          surface-p5 = mkNixosSystem { hostName = "surface-p5"; systemStateVersion = "25.11"; };
        };

        homeManagerModules = {
          neovim = import ./modules/home-manager/neovim; # neovim wrapper with config
        };
      };

  inputs = {
    # Stable and Unstable Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/release-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #nixos hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Hyprland
    hyprland = {
      url = "github:hyprwm/Hyprland?ref=v0.52.1"; # locked
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprsplit = {
      url = "github:shezdy/hyprsplit?ref=v0.52.1"; # locked
      inputs.hyprland.follows = "hyprland";
    };

    ags.url = "github:aylur/ags?ref=v3.1.1";
    agsShell = {
      url = "github:leierx/ags-dotfiles";
      inputs.ags.follows = "ags";
    };
  };
}

