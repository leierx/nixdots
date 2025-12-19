{
  inputs = (import ./flakeInputs.nix);

  outputs =
    { nixpkgs, home-manager, ... }@flakeInputs:
    let
      mkNixosSystem = (import ./lib/mk-nixos-system.nix { inherit flakeInputs; });
    in
    {
      nixosConfigurations = {
        desktop = mkNixosSystem {
          hostName = "desktop";
          systemStateVersion = "25.11";
        };
        surface-p5 = mkNixosSystem {
          hostName = "surface-p5";
          systemStateVersion = "25.11";
        };
      };

      homeManagerModules = {
        neovim = import ./modules/home-manager/neovim; # neovim wrapper with config
      };
    };
}
