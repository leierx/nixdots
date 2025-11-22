{ flakeInputs, pkgs, ... }:
{
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    settings = {
      auto-optimise-store = true;
      flake-registry = ""; # Disable global registry
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "@wheel" ];
    };

    # Thanks to: https://nixos-and-flakes.thiscute.world/best-practices/nix-path-and-flake-registry#custom-nix-path-and-flake-registry
    registry.nixpkgs.flake = flakeInputs.nixpkgs; # make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
    channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.
    nixPath = [ "nixpkgs=${flakeInputs.nixpkgs.outPath}" ];
  };

  # allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # bloat removal
  documentation.nixos.enable = false;
  programs.command-not-found.enable = false;
  networking.dhcpcd.enable = false;
  services.xserver.excludePackages = [ pkgs.xterm ];

  # default editor nano -> neovim
  programs.nano.enable = false;
  programs.neovim.defaultEditor = true;
  programs.neovim.enable = true;

  # clean /tmp on boot
  boot.tmp.cleanOnBoot = true;

  # syslog
  services.journald.extraConfig = "MaxRetentionSec=90day";
}
