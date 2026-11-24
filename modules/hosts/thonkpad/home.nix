root: {
  flake.modules.homeManager."nixosConfigurations/thonkpad/home" = {
    imports = [ root.config.flake.modules.homeManager.homelab ];
    programs.pi-coding-agent.settings = {
      defaultProvider = "claude-bridge";
      defaultModel = "claude-opus-5-5";
      defaultThinkingLevel = "high";
    };
  };
}
