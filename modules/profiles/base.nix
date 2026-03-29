{ self, ... }:
{
  flake.modules.profiles.base = {
    imports = [
      self.modules.nixos.bootloader
      self.modules.nixos.doas
      self.modules.nixos.git
      self.modules.nixos.journald
      self.modules.nixos.locale
      self.modules.nixos.networkManager
      self.modules.nixos.nixConfig
      self.modules.nixos.plymouth
      self.modules.nixos.user
      self.modules.nixos.shell
    ];
  };
}
