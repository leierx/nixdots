# Unfree packages are opted into by name rather than allowed wholesale.
{ config, lib, ... }:
let
  predicate = pkg: builtins.elem (lib.getName pkg) config.nixpkgs.allowedUnfreePackages;
in
{
  options.nixpkgs.allowedUnfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Unfree package names this flake is allowed to evaluate";
  };

  config.flake.modules = {
    nixos.core.nixpkgs.config.allowUnfreePredicate = predicate;
    darwin.core.nixpkgs.config.allowUnfreePredicate = predicate;
  };
}
