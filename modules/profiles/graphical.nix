{ config, ... }:
let
  outerConfig = config;
in
{
  modules.nixos.profiles.graphical =
    { config, lib, ... }:
    let
      cfg = config.profileConfig.graphical;
    in
    {
      options.profileConfig.graphical.user = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "leier";
      };

      imports = [
        outerConfig.modules.nixos.displayManager
        outerConfig.modules.nixos.sound
        outerConfig.modules.nixos.plymouth
        outerConfig.modules.nixos.gtk
        outerConfig.modules.nixos.fonts
        outerConfig.modules.nixos.hyprland
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
