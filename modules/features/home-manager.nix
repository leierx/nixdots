# NixOS wiring for the primary user's home-manager configuration on this host.
root@{ inputs, lib, ... }:
{
  flake.modules.nixos.home-manager =
    { config, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        # a pre-existing file at a managed path would otherwise fail activation
        backupFileExtension = "hm-bak";

        users.${root.config.identity.username}.imports = [
          { home.stateVersion = lib.mkDefault lib.trivial.release; }
          (root.config.flake.modules.homeManager."nixosConfigurations/${config.networking.hostName}/home"
            or { }
          )
        ];
      };
    };
}
