{
  outputs = { nixpkgs, home-manager, ... }@flakeInputs:
    let
      mkSystem = (import ./lib/mk-system.nix { inherit flakeInputs; });
    in
      {
        nixosConfigurations = {
          desktop = mkSystem { hostName = "desktop"; systemStateVersion = "25.05"; };
          laptop = mkSystem { hostName = "laptop"; systemStateVersion = "25.05"; };
        };
      };

  inputs = {
    # Stable and Unstable Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/release-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Hyprland
    hyprland.url = "git+https://github.com/hyprwm/Hyprland.git?ref=refs/tags/v0.49.0&submodules=1";
    hyprsplit.url = "git+https://github.com/shezdy/hyprsplit.git?ref=refs/tags/v0.49.0";
    hyprsplit.inputs.hyprland.follows = "hyprland";
    ags.url = "github:aylur/ags"; ags.inputs.nixpkgs.follows = "nixpkgs-unstable";
    agsShell.url = "github:leierx/AGS-dotfiles"; agsShell.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };
}

