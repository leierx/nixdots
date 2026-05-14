{ lib, ... }:
{
  options.flake = {
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
      };
      default = { };
      description = "NixOS modules and host definitions";
    };

    modules.homeManager = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "Reusable Home Manager modules";
    };

    factories = {
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
  };
}
