# Builds `flake.darwinConfigurations` from `darwinHosts.<hostname>`.
{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  defaults = hostname: host: {
    networking.hostName = lib.mkDefault hostname;
    nixpkgs.hostPlatform = lib.mkDefault host.system;
    # nix-darwin takes an int here, not a release string
    system.stateVersion = lib.mkDefault 7;
  };

  mkHost =
    hostname: host:
    inputs.nix-darwin.lib.darwinSystem {
      modules = [
        (defaults hostname host)
        (config.flake.modules.darwin."darwinConfigurations/${hostname}" or { })
      ];
    };
in
{
  options.darwinHosts = mkOption {
    type = types.attrsOf (
      types.submodule {
        options.system = mkOption {
          type = types.str;
          default = "aarch64-darwin";
        };
      }
    );
    default = { };
    description = "nix-darwin hosts, keyed by hostname";
  };

  config.flake.darwinConfigurations = lib.mapAttrs mkHost config.darwinHosts;
}
