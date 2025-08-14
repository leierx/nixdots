{ lib, ... }:
{
  options.dots.gui.enable = lib.mkEnableOption "enable graphical system";

  imports = [
    ./apps
    ./base
    ./desktops
    ./display-manager.nix
  ];
}
