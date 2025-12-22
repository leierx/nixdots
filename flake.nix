{
  outputs =
    { nixpkgs, ... }@flakeInputs:
    let
      mkNixosSystem = (import ./lib/mk-nixos-system.nix { inherit flakeInputs; });
    in
    {
      nixosConfigurations = {
        desktop = mkNixosSystem { hostName = "desktop"; };
        surface-p5 = mkNixosSystem { hostName = "surface-p5"; };
      };

      packages = (import ./packages { inherit nixpkgs; });

      homeManagerModules = {
        neovim = import ./modules/home-manager/neovim;
      };
    };

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # deterministic disk setup
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # hardware helper
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # neovim configuration
    neovim-dotfiles.url = "github:leierx/neovim-dotfiles";
    neovim-dotfiles.flake = false;

    # hyprland
    hyprland.url = "github:hyprwm/Hyprland?ref=v0.52.1";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprsplit.url = "github:shezdy/hyprsplit?ref=v0.52.1";
    hyprsplit.inputs.hyprland.follows = "hyprland";
    ags.url = "github:aylur/ags?ref=v3.1.1";
    agsShell.url = "github:leierx/ags-dotfiles";
    agsShell.inputs.ags.follows = "ags";
  };
}
