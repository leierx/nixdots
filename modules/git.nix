{
  flake.modules.nixos.git.programs.git.enable = true;

  flake.modules.homeManager.git =
    { config, lib, ... }:
    let
      cfg = config.flakeModules.git;
    in
    {
      options.flakeModules.git = {
        userName = lib.mkOption {
          type = lib.types.singleLineStr;
          default = "Lars Smith Eier";
          description = "Full name for git commits (user.name)";
        };
        userEmail = lib.mkOption {
          type = lib.types.singleLineStr;
          default = "larssmitheier@protonmail.com";
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
