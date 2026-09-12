{ config, ... }:
{
  nixosHosts.desktop = { };

  flake.modules.nixos."nixosConfigurations/desktop".imports = with config.flake.modules.nixos; [
    base
    workstation
    grub
    efi
    gaming
    incus
  ];
}
