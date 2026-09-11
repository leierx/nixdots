{ config, ... }:
{
  flake.modules.darwin.core.imports = with config.flake.modules.darwin; [
    home-manager
  ];
}
