{ inputs, lib, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ];

  # Declare factories as mergeable options (not wrapped by flake-parts)
  options.flake.factories = {
    nixos = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      description = "Factory functions that produce NixOS modules";
    };
    homeManager = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      description = "Factory functions that produce Home Manager modules";
    };
  };
}
