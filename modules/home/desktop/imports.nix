{ config, ... }:
{
  flake.modules.homeManager.desktop.imports = with config.flake.modules.homeManager; [
    cursor
    gtk
    hyprland
    neovim
    qt
    rofi
    wezterm
  ];
}
