{ inputs, ... }:
{
  modules.nixos.factories.homeManager = user: {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      backupFileExtension = "backup";
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${user}.home = {
        username = user;
        homeDirectory = "/home/${user}";
        stateVersion = inputs.home-manager.inputs.nixpkgs.lib.trivial.release;
      };
    };
  };
}
