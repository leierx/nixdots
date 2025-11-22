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

  # Nautilus fixes FUCK THIS IS LOOPING
  # services.gvfs.enable = lib.elem pkgs.nautilus config.environment.systemPackages; # nautilus functionallity
  # services.gnome.sushi.enable = lib.elem pkgs.nautilus config.environment.systemPackages; # nautilus previews
  # programs.file-roller.enable = lib.elem pkgs.nautilus config.environment.systemPackages; # nautilus archive manager

  # hyprlock fix
  security.pam.services.hyprlock = lib.mkIf hmHyprlockEnabled {};
}
