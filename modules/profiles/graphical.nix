{ config, ... }:
let
  outerConfig = config;
in
{
  modules.nixos.profiles.graphical =
    { config, ... }:
    let
      cfg = config.profileConfig;
    in
    {
      imports = [
        outerConfig.modules.nixos.displayManager
        outerConfig.modules.nixos.sound
        outerConfig.modules.nixos.plymouth
        outerConfig.modules.nixos.gtk
        outerConfig.modules.nixos.fonts
        outerConfig.modules.nixos.mango
        outerConfig.modules.overlays.vesktop
      ];

      config = {
        home-manager.users.${cfg.user}.imports = [
          outerConfig.modules.homeManager.cursor
          outerConfig.modules.homeManager.gtk
          outerConfig.modules.homeManager.neovim
          outerConfig.modules.homeManager.qt
        ];
      };
    };
}
