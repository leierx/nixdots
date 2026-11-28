{
  flake.modules.homeManager.ssh = {
    services.ssh-agent.enable = true;

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "github.com".User = "git";
        # a key's passphrase is asked once per session
        "*".AddKeysToAgent = "yes";
      };
    };
  };
}
