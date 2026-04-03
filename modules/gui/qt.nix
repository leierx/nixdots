{ self, ... }:
{
  flake.modules.nixos.qt =
    { ... }:
    {
      home-manager.sharedModules = [ self.modules.homeManager.qt ];
    };

  flake.modules.homeManager.qt = {
    qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style.name = "adwaita-dark";
    };
  };
}
