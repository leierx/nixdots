# A minimal `perSystem`: one deferred module evaluated per `systems` entry,
# producing the system-keyed outputs. Definitions merge like any module.
{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  evalSystem =
    system:
    (lib.evalModules {
      class = "perSystem";
      specialArgs = {
        inherit inputs system;
        root = config;
      };
      modules = [
        config.perSystem
        {
          options = {
            packages = mkOption {
              type = types.lazyAttrsOf types.raw;
              default = { };
            };
            checks = mkOption {
              type = types.lazyAttrsOf types.raw;
              default = { };
            };
            devShells = mkOption {
              type = types.lazyAttrsOf types.raw;
              default = { };
            };
            formatter = mkOption {
              type = types.nullOr types.raw;
              default = null;
            };
          };

          config._module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        }
      ];
    }).config;

  evaluated = lib.genAttrs config.systems evalSystem;

  collect = attr: lib.mapAttrs (_: system: system.${attr}) evaluated;
in
{
  options = {
    systems = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Systems for which per-system outputs are produced";
    };

    perSystem = mkOption {
      type = types.deferredModule;
      default = { };
      description = "Module evaluated once per entry of `systems`";
    };
  };

  config.systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];

  config.flake = {
    packages = collect "packages";
    checks = collect "checks";
    devShells = collect "devShells";
    formatter = lib.filterAttrs (_: v: v != null) (collect "formatter");
  };
}
