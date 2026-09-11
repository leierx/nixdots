# Builds `flake.nixosConfigurations` from `nixosHosts.<hostname>`.
#
# Each host is assembled from the `core` aspect plus everything any module
# contributed to `flake.modules.nixos."nixosConfigurations/<hostname>"`.
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  defaults = hostname: host: {
    networking.hostId = lib.mkDefault (builtins.substring 0 8 (builtins.hashString "sha256" hostname));
    networking.hostName = lib.mkDefault hostname;
    nixpkgs.hostPlatform = lib.mkDefault host.system;
    nixpkgs.config.allowUnfree = lib.mkDefault true;
    system.stateVersion = lib.mkDefault lib.trivial.release;
  };

  mkHost =
    hostname: host:
    lib.nixosSystem {
      modules = [
        (defaults hostname host)
        config.flake.modules.nixos.core
        (config.flake.modules.nixos."nixosConfigurations/${hostname}" or { })
      ];
    };
in
{
  options.nixosHosts = mkOption {
    type = types.attrsOf (
      types.submodule {
        options.system = mkOption {
          type = types.str;
          default = "x86_64-linux";
        };
      }
    );
    default = { };
    description = "NixOS hosts, keyed by hostname";
  };

  config.flake.nixosConfigurations = lib.mapAttrs mkHost config.nixosHosts;
}
