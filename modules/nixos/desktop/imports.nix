{ config, ... }:
{
  flake.modules.nixos.desktop.imports = with config.flake.modules.nixos; [
    display-manager
    fonts
    gtk
    hyprland
    plymouth
    sound
  ];
}
