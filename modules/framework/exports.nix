# Conventional flake outputs, so external flakes can import single modules
# as `inputs.nixdots.nixosModules.<aspect>`.
{ config, lib, ... }:
let
  registry = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
  };
in
{
  options.flake = {
    nixosModules = registry;
    homeModules = registry;
    darwinModules = registry;
  };

  config.flake = {
    nixosModules = config.modules.nixos;
    homeModules = config.modules.home;
    darwinModules = config.modules.darwin;
  };
}
