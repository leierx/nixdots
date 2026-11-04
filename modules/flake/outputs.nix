{ lib, ... }:
let
  inherit (lib) mkOption types;

  output =
    description:
    mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
      inherit description;
    };

  # the class makes a wrong-class import a type error; the key dedups an aspect imported twice
  tag =
    class: name: module:
    { ... }:
    {
      key = "flake.modules.${class}.${name}";
      _class = class;
      _file = "flake.modules.${class}.${name}";
      imports = [ module ];
    };
in
{
  options.flake = {
    modules = mkOption {
      type = types.lazyAttrsOf (types.lazyAttrsOf types.deferredModule);
      default = { };
      apply = lib.mapAttrs (class: lib.mapAttrs (tag class));
      description = ''
        Groups of modules published by the flake, keyed by module class
        (`nixos`, `homeManager`) and then by aspect name. Values merge across
        files, so one aspect may be assembled by any number of top-level modules.
      '';
    };

    nixosConfigurations = output "Evaluated NixOS systems";

    formatter = output "Flake formatter, keyed by system";
    checks = output "Flake checks, keyed by system";
    devShells = output "Development shells, keyed by system";
    packages = output "Packages, keyed by system";
  };
}
