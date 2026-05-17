{
  flake.modules.nixos.profileOptions =
    { lib, ... }:
    {
      options.flakeModules.profile = {
        user = lib.mkOption {
          type = lib.types.singleLineStr;
          default = "leier";
          description = "Home Manager user that profiles configure.";
        };
      };
    };
}
