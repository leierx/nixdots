{
  flake.modules.nixos.nix =
    { lib, ... }:
    {
      # the `nixpkgs` registry entry and NIX_PATH come from nixpkgs.flake.source (lib.nixosSystem)
      nix = {
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 14d";
        };

        settings = {
          auto-optimise-store = true;
          flake-registry = lib.mkForce ""; # Disable global registry
          warn-dirty = false;
          max-jobs = "auto";
          builders-use-substitutes = true;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          substituters = [ "https://nix-community.cachix.org" ];
          trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
        };

        channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead
      };
    };
}
