# Builds `flake.homeConfigurations` from `homeConfigs.<name>`, for
# home-manager on machines this flake does not own (non-NixOS boxes).
{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  mkConfig =
    name: cfg:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = cfg.system;
        config.allowUnfree = true;
      };
      modules = [
        { home.stateVersion = lib.mkDefault lib.trivial.release; }
        (config.flake.modules.homeManager."homeConfigurations/${name}" or { })
      ];
    };
in
{
  options.homeConfigs = mkOption {
    type = types.attrsOf (
      types.submodule {
        options.system = mkOption {
          type = types.str;
          default = "x86_64-linux";
        };
      }
    );
    default = { };
    description = "Standalone home-manager configurations, keyed by name";
  };

  config.flake.homeConfigurations = lib.mapAttrs mkConfig config.homeConfigs;
}
