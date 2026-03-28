{ config, ... }:
{
  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = config.flake.settings.user.fullName;
          email = config.flake.settings.user.email;
        };
        credential.helper = "cache --timeout=36000";
        safe.directory = "*";
      };
    };
  };
}
