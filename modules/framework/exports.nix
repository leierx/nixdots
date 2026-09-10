{ config, lib, ... }:
let
  registry = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
  };
in
{
  options = {
    nixosModules = registry;
    homeModules = registry;
    darwinModules = registry;
  };

  # conventional flake outputs so external flakes can import single modules
  config = {
    nixosModules = config.modules.nixos;
    homeModules = config.modules.home;
    darwinModules = config.modules.darwin;
  };
}
