{ config, ... }:
{
  bundles.minimal = {
    nixos = with config.modules.nixos; [
      bootloader
      basePackages
      nixosConfig
      doas
      git
      journald
      locale
      network
      podman
      root
      user
      unstableNixpkgs
    ];
    home = with config.modules.home; [
      git
      locale
      opencode
      tmux
      user
      xdgUserDirs
    ];
  };
}
