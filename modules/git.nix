{ ... }:
{
  flake.modules.nixos.git.programs.git.enable = true;

  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      settings = {
        user.name = "Lars Smith Eier";
        user.email = "larssmitheier@protonmail.com";
        credential.helper = "cache --timeout=36000";
        safe.directory = "*";
      };
    };
  };
}
