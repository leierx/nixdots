# Template for standalone home-manager on a non-NixOS box
{ config, ... }:
{
  homeConfigs.example-home = { };

  flake.modules.homeManager."homeConfigurations/example-home".imports =
    with config.flake.modules.homeManager; [ base ];
}
