{ config, ... }:
{
  bundles.graphical = {
    nixos = with config.flake.modules.nixos; [
      display-manager
      sound
      plymouth
      gtk
      fonts
      hyprland
    ];
    home = with config.flake.modules.homeManager; [
      cursor
      gtk
      hyprland
      neovim
      qt
      rofi
      wezterm
    ];
  };
}
