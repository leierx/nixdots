{ config, ... }:
{
  nixosHosts.desktop = { };

  flake.modules.nixos."nixosConfigurations/desktop".imports = with config.flake.modules.nixos; [
    desktop
    gaming
    incus
    efi
    grub
  ];
}
