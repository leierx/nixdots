{ config, lib, flakeInputs, ... }:

let
  cfg = config.dots.core.nix;
in
{
  options.dots.core.nix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "core Nix and Nixpkgs configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure host platform is pinned
    nixpkgs.config.hostPlatform = config.nixpkgs.system;
    nixpkgs.config.allowUnfree = true;

    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };

      settings = {
        auto-optimise-store = true;
        flake-registry = ""; # no global registry
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [ "root" "@wheel" ];
        substituters = [
          "https://hyprland.cachix.org"
        ];
        trusted-public-keys =[
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };

      registry.nixpkgs.flake = flakeInputs.nixpkgs; # align `nix run` with pkgs from flake
      channel.enable = false; # ditch nix-channel
    };
  };
}
