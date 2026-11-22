root: {
  flake.modules.homeManager."nixosConfigurations/thonkpad/home" = {
    imports = [ root.config.flake.modules.homeManager.homelab ];
    programs.pi-coding-agent.settings = {
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4.1-flash";
      defaultThinkingLevel = "max";
    };
  };
}
