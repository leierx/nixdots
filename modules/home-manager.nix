{ inputs, ... }:
{
  flake.factories.nixos.homeManager =
    username:
    { lib, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        backupFileExtension = "backup";
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username}.home = {
          inherit username;
          homeDirectory = lib.mkDefault "/home/${username}";
          stateVersion = lib.mkDefault (inputs.home-manager.inputs.nixpkgs.lib.trivial.release);
        };
      };
    };
}
