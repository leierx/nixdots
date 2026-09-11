{ config, ... }:
{
  flake.modules.homeManager."homeConfigurations/thonkpad".imports =
    with config.flake.modules.homeManager; [
      desktop
    ];
}
