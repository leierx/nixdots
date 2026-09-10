{ ... }:
{
  modules.nixos.git.programs.git.enable = true;

  modules.home.git = {
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
