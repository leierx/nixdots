{ config, lib, ... }:
{
  options.flake.settings.user = with lib; {
    username = mkOption {
      type = types.singleLineStr;
      default = "leier";
    };

    fullName = mkOption {
      type = types.singleLineStr;
      default = "Lars Smith Eier";
    };

    email = mkOption {
      type = types.singleLineStr;
      default = "larssmitheier@protonmail.com";
    };

    homeDirectory = mkOption {
      type = types.singleLineStr;
      default = "/home/${config.flake.nixdots.user.username}";
    };
  };
}
