root: {
  flake.modules.homeManager."nixosConfigurations/thonkpad/home" = {
    imports = [ root.config.flake.modules.homeManager.homelab ];
  };
}
