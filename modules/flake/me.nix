# Who this flake is for. Declared once at the top level so users, git,
# home-manager and anything else can read it instead of hardcoding it.
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.me = {
    username = mkOption {
      type = types.singleLineStr;
      description = "Login name of the primary user";
    };
    fullName = mkOption {
      type = types.singleLineStr;
      description = "Name used for git authorship";
    };
    email = mkOption {
      type = types.singleLineStr;
      description = "Email used for git authorship";
    };
  };

  config.me = {
    username = "leier";
    fullName = "Lars Smith Eier";
    email = "larssmitheier@protonmail.com";
  };
}
