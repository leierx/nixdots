{ pkgs, ... }:
{
  environment.systemPackages = [
    (import ./nixos-activate-fzf.nix { inherit pkgs; })
  ];
}
