{
  config,
  inputs,
  lib,
  ...
}:
let
  user = config.flake.settings.user;
in
{
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
  };

  config.flake.nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
    name: hostModule:
    lib.nixosSystem {
      modules = [
        {
          networking.hostId = lib.mkDefault (builtins.substring 0 8 (builtins.hashString "sha256" name));
          networking.hostName = lib.mkDefault name;
          nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
          system.stateVersion = lib.mkDefault lib.trivial.release;
        }
        hostModule
      ];
    }
  );
}
