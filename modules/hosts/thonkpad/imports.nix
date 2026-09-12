{ config, ... }:
{
  nixosHosts.thonkpad = { };

  flake.modules.nixos."nixosConfigurations/thonkpad".imports = with config.flake.modules.nixos; [
    base
    workstation
    gaming
  ];
}
