{ config, lib, ... }:
{
  options.meta = with lib; {
    user = {
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
        default = "/home/${config.meta.user.username}";
      };
    };
  };
}
