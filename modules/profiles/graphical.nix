{ self, config, ... }:
let
  username = config.meta.user.username;
in
{
  flake.modules.nixos.profileGraphical = {
    imports = [
      self.modules.nixos.profileMinimal
      self.modules.nixos.displayManager
      self.modules.nixos.sound
      self.modules.nixos.plymouth
      self.modules.nixos.gtk
      self.modules.nixos.fonts
      self.modules.nixos.hyprland
    ];

    home-manager.users.${username}.imports = [
      self.modules.homeManager.cursor
      self.modules.homeManager.gtk
      self.modules.homeManager.qt
    ];
  };
}
