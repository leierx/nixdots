# The flake output surface: `flake.nix` returns `config.flake`, so every option
# declared here is an output. `flake.modules.<class>.<aspect>` is the dendritic
# registry storing class-tagged modules as values, merged by name.
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

  # Tag stored modules with class and origin, so a wrong-class import is a
  # plain type error instead of "undeclared option" noise.
  tag =
    class: name: module:
    { ... }:
    {
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
