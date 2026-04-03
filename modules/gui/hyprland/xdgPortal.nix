{
  flake.modules.homeManager.hyprland =
    { pkgs, ... }:
    {
      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
        config.hyprland.default = [
          "hyprland"
          "gtk"
        ];
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };
    };
}
