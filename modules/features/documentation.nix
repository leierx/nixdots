{
  flake.modules.nixos.documentation.documentation = {
    nixos.enable = false;
    info.enable = false;
    doc.enable = false;
    # apropos and man -k; built by a service rather than with every system
    man.cache = {
      enable = true;
      generateAtRuntime = true;
    };
  };

  flake.modules.homeManager.documentation.programs.man.generateCaches = true;
}
