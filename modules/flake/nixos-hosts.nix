# Builds `flake.nixosConfigurations` from `nixosHosts.<hostname>`.
#
# A host is exactly what its own aspect imports; the only things added
# implicitly are the identity of the machine and a stateVersion default,
# both of which a host may override.
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
    system.stateVersion = lib.mkDefault lib.trivial.release;
  };

  mkHost =
    hostname: host:
    lib.nixosSystem {
      modules = [
        (defaults hostname host)
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
