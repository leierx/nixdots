{ inputs, ... }:
{
  flake.modules.profiles.nixos.graphical = {
    imports = with inputs.self.modules; [
      profiles.nixos.minimal
      nixos.sound
      nixos.gtk
      nixos.fonts
      nixos.cursor
      nixos.displayManager
    ];
  };
}
