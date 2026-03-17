{
  outputs =
    { ... }@inputs:
    let
      mkNixosSystem = (import ./lib/mk-nixos-system.nix { inherit inputs; });
      neovimModule = (import ./modules/home-manager/neovim/flake.nix).outputs { };
    in
    {
      homeManagerModules.neovim = neovimModule.homeManagerModules.default;

      nixosConfigurations = {
        desktop = mkNixosSystem { hostName = "desktop"; };
        thonkpad = mkNixosSystem { hostName = "thonkpad"; };
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
