{ config, inputs, ... }:
let
  user = config.flake.settings.user;
in
{
  flake.modules.nixos.homeManager =
    { lib, ... }:
    {
      imports = [ inputs.home-manager.modules.nixos.home-manager ];

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
    };
}
