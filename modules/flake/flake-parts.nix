{ lib, ... }:
{
  options = {
    nixosConfigurations = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      description = "Attrset of NixOS system configurations";
    };

    modules.nixos = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf lib.types.deferredModule;
        options.hosts = lib.mkOption {
          type = lib.types.attrsOf lib.types.deferredModule;
          default = { };
          description = "Per-host NixOS module definitions";
        };
        options.factories = lib.mkOption {
          type = lib.types.lazyAttrsOf (lib.types.functionTo lib.types.deferredModule);
          default = { };
          description = "Functions that produce NixOS modules from arguments";
        };
        options.profiles = lib.mkOption {
          type = lib.types.attrsOf lib.types.deferredModule;
          default = { };
          description = "Composable bundles of NixOS modules";
        };
      };
      default = { };
      description = "NixOS modules and host definitions";
    };

    modules.homeManager = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "Reusable Home Manager modules";
    };

    modules.overlays = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "Overlay modules (each sets nixpkgs.overlays)";
    };

    packages = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
      default = { };
      description = "Flake packages output, keyed by system then name";
    };
  };
}
