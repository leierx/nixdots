{ lib, ... }:
{
  options.profileConfig = {
    user = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "leier";
      description = "Home Manager user that the minimal profile configures.";
    };
  };
}
