{ self, ... }:
{
  flake.modules.profiles.nixos.minimal = {
    imports = with self.modules; [
      nixos.bootloader
      nixos.doas
      nixos.git
      nixos.journald
      nixos.locale
      nixos.networkManager
      nixos.nixConfig
      nixos.plymouth
      nixos.editor
      nixos.debloat
      nixos.user
      nixos.shell
      nixos.overlays.vesktop
      #
      overlays.vesktop
    ];
  };
}
