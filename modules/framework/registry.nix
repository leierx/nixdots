{ lib, ... }:
let
  registry =
    description:
    lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
      inherit description;
    };

  configurations = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
  };

  classModules = lib.mkOption {
    type = lib.types.listOf lib.types.deferredModule;
    default = [ ];
  };
in
{
  options = {
    modules.nixos = registry "Reusable NixOS modules";
    modules.darwin = registry "Reusable nix-darwin modules";
    modules.home = registry "Reusable home-manager modules";

    bundles = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            nixos = classModules;
            darwin = classModules;
            home = classModules;
          };
        }
      );
      default = { };
      description = "Named class-keyed module lists, consumed by systems.<name>.bundles";
    };

    systems = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            class = lib.mkOption {
              type = lib.types.enum [
                "nixos"
                "darwin"
                "home"
              ];
              default = "nixos";
            };
            platform = lib.mkOption {
              type = lib.types.str;
              default = "x86_64-linux";
            };
            user = lib.mkOption {
              type = lib.types.nullOr lib.types.singleLineStr;
              default = null;
              description = "Primary user; wires home-manager and feeds feature user options";
            };
            bundles = lib.mkOption {
              type = lib.types.listOf lib.types.singleLineStr;
              default = [ ];
            };
            modules = classModules;
          };
        }
      );
      default = { };
      description = "Declarative systems, built into *Configurations by framework/build.nix";
    };

    theme = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrs;
        options = {
          palettes = lib.mkOption {
            type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
            default = { };
          };
          colors = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
          };
          rgb = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
          };
          vars = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      };
      default = { };
    };

    nixosConfigurations = configurations;
    darwinConfigurations = configurations;
    homeConfigurations = configurations;
  };
}
