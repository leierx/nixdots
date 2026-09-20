# The flake output surface: `flake.nix` returns `config.flake`, so every option
# declared here is an output. `flake.modules.<class>.<aspect>` is the dendritic
# registry storing class-tagged modules as values, merged by name.
{ lib, ... }:
let
  inherit (lib) mkOption types;

  configurations =
    description:
    mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
      inherit description;
    };

  bySystem =
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
    if class == "generic" then
      module
    else
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
        (`nixos`, `homeManager`, `darwin`, or `generic`) and then by aspect
        name. Values merge across files, so one aspect may be assembled by
        any number of top-level modules.
      '';
    };

    nixosConfigurations = configurations "Evaluated NixOS systems";
    darwinConfigurations = configurations "Evaluated nix-darwin systems";
    homeConfigurations = configurations "Evaluated standalone home-manager configurations";

    formatter = bySystem "Flake formatter, keyed by system";
    checks = bySystem "Flake checks, keyed by system";
    devShells = bySystem "Development shells, keyed by system";
    packages = bySystem "Packages, keyed by system";
  };
}
