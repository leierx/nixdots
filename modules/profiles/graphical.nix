{ config, ... }:
let
  outerConfig = config;
in
{
  flake.modules.nixos.graphical =
    { config, ... }:
    {
      imports = [
        outerConfig.flake.modules.nixos.minimal
        outerConfig.flake.modules.nixos.displayManager
        outerConfig.flake.modules.nixos.sound
        outerConfig.flake.modules.nixos.plymouth
        outerConfig.flake.modules.nixos.gtk
        outerConfig.flake.modules.nixos.fonts
        outerConfig.flake.modules.nixos.hyprland
      ];

      config = {
        home-manager.users.${config.dot.user.name}.imports = [
          outerConfig.flake.modules.homeManager.cursor
          outerConfig.flake.modules.homeManager.gtk
          outerConfig.flake.modules.homeManager.qt
        ];
      };
    };
}
