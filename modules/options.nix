{ lib, ... }:
{
  options.flake = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Top-level flake outputs";
  };
}
