{ config, ... }:
{
  flake.modules.nixos.profileMinimal = {
    imports = [
      config.flake.modules.nixos.bootloader
    ];
  };
}
