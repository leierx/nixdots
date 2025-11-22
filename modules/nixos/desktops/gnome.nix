{ pkgs, ... }:
{
  # install
  services.xserver.desktopManager.gnome.enable = true;

  # disable gnome bloat
  services.gnome.core-apps.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [ gnome-tour gnome-user-docs ];
}
