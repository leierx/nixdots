{ lib, pkgs, ... }:
{
  imports = [
    ./cursor.nix
    ./gtk.nix
    ./qt.nix
    ./xdg.nix
  ];
}
