{ config, ... }:
{
  bundles.graphical = {
    nixos = with config.modules.nixos; [
      displayManager
      sound
      plymouth
      gtk
      fonts
      hyprland
    ];
    home = with config.modules.home; [
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
