{
  flake.modules.homeManager."nixosConfigurations/thonkpad/home" = {
    piAgent.settings = {
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4.1-flash";
      defaultThinkingLevel = "high";
    };
  };
}
