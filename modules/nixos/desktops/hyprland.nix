{ config, lib, pkgs, flakeInputs, ... }:
let
  hmUsers = config.home-manager.users or {};
  hmHyprlockEnabled = builtins.any (uCfg: uCfg.programs.hyprlock.enable or false) (builtins.attrValues hmUsers);
in
{
  # Install
  programs.hyprland.enable = true;
  programs.hyprland.package = flakeInputs.hyprland.packages.${pkgs.system}.hyprland;
  programs.hyprland.portalPackage = flakeInputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;

  # Nautilus file-manager
  services.gvfs.enable = true;
  services.gnome.sushi.enable = true;
  programs.file-roller.enable = true;
  environment.systemPackages = [ pkgs.nautilus ];

  # hyprlock fix
  security.pam.services.hyprlock = lib.mkIf hmHyprlockEnabled {};
}
