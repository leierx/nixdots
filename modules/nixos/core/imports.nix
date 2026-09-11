{ config, ... }:
{
  flake.modules.nixos.core.imports = with config.flake.modules.nixos; [
    base-packages
    boot
    doas
    git
    home-manager
    journald
    locale
    network
    nix
    podman
    root
    unstable-nixpkgs
    user
  ];
}
