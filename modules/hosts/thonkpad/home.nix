root: {
  flake.modules.homeManager."nixosConfigurations/thonkpad/home" = {
    imports = [ root.config.flake.modules.homeManager.homelab ];

    piAgent.settings = {
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4.1-flash";
      defaultThinkingLevel = "high";
    };

    programs.gh = {
      enable = true;
      settings.aliases.co = "pr checkout";
    };
  };
}
