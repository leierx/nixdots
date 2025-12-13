{ config, lib, pkgs, flakeInputs, ... }:
let
  hmUsers = config.home-manager.users or {};
  hmHyprlockEnabled = builtins.any (uCfg: uCfg.programs.hyprlock.enable or false) (builtins.attrValues hmUsers);
in
{
  # Install
  programs.hyprland.enable = true;
  programs.hyprland.package = flakeInputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  programs.hyprland.portalPackage = flakeInputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

  # Nautilus file-manager
  services.gvfs.enable = true;
  services.gnome.sushi.enable = true;
  environment.systemPackages = [ pkgs.nautilus ];

  # hyprlock fix
  security.pam.services.hyprlock = lib.mkIf hmHyprlockEnabled {};

  # cachix
  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };
}
