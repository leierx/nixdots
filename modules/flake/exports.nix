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
    nixosModules = config.flake.modules.nixos;
    homeModules = config.flake.modules.homeManager;
    darwinModules = config.flake.modules.darwin;
  };
}
