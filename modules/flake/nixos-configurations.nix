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
          imports = [ inputs.home-manager.modules.nixos.home-manager ];
          #
          home-manager = {
            backupFileExtension = "backup";
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${user.username} = {
              home = {
                username = lib.mkDefault user.username;
                homeDirectory = lib.mkDefault user.homeDirectory;
                stateVersion = lib.mkDefault inputs.home-manager.inputs.nixpkgs.lib.trivial.release;
              };
            };
          };
          #
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
