{ inputs, ... }:
{
  modules.nixos.nixosConfig =
    { lib, ... }:
    {
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
          cores = 0;
          max-jobs = "auto";
          builders-use-substitutes = true;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          substituters = [ "https://nix-community.cachix.org" ];
          trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
        };

        # make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake
        registry.nixpkgs.flake = inputs.nixpkgs;
        channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead
        nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
      };

      # bloat removal
      documentation.nixos.enable = false;
      networking.dhcpcd.enable = false;
      # change nixos default editor to neovim
      programs.nano.enable = false;
      programs.neovim = {
        enable = true;
        vimAlias = true;
        defaultEditor = true;
      };
    };
}
