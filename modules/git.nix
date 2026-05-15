{ config, ... }:
let
  outerConfig = config;
in
{
  flake.modules.nixos.git.programs.git.enable = true;

  flake.modules.homeManager.git =
    { config, lib, ... }:
    let
      cfg = config.dot.git;
    in
    {
      options.dot.git = {
        userName = lib.mkOption {
          type = lib.types.singleLineStr;
          default = outerConfig.flake.defaults.fullName;
          description = "Full name for git commits (user.name)";
        };
        userEmail = lib.mkOption {
          type = lib.types.singleLineStr;
          default = outerConfig.flake.defaults.email;
          description = "Email for git commits (user.email)";
        };
      };

      config = {
        programs.git = {
          enable = true;
          settings = {
            user.name = cfg.userName;
            user.email = cfg.userEmail;
            credential.helper = "cache --timeout=36000";
            safe.directory = "*";
          };
        };
      };
    };
}
