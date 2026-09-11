{ config, ... }:
{
  bundles.minimal = {
    nixos = with config.flake.modules.nixos; [
      bootloader
      base-packages
      nix
      doas
      git
      journald
      locale
      network
      podman
      root
      user
      unstable-nixpkgs
    ];
    home = with config.flake.modules.homeManager; [
      git
      locale
      opencode
      tmux
      xdg-user-dirs
      zsh
    ];
  };
}
