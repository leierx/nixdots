{ lib, ... }:
{
  options.flake.defaults = {
    username = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "leier";
      description = ''
        Default Unix username used by modules like user, shell, home-manager.
        Each module declares its own option that defaults to this value, so
        modules remain independently importable but share a single source
        of truth in normal use.
      '';
    };

    fullName = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "Lars Smith Eier";
      description = "Default full name used by modules like git.";
    };

    email = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "larssmitheier@protonmail.com";
      description = "Default email used by modules like git.";
    };
  };
}
