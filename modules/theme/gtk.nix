{
  flake.modules.nixos.gtk.programs.dconf.enable = true;

  flake.modules.homeManager.gtk =
    { pkgs, ... }:
    let
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-enable-animations = 1;
        gtk-enable-primary-paste = 0;
        gtk-recent-files-enabled = 0;
        gtk-enable-event-sounds = 0;
        gtk-enable-input-feedback-sounds = 0;
        gtk-error-bell = 0;
      };
    in
    {
      dconf.enable = true;

      dconf.settings = {
        "org/gnome/desktop/interface".color-scheme = "prefer-dark";
      };

      gtk = {
        enable = true;

        font = {
          name = "Adwaita Sans";
          package = pkgs.adwaita-fonts;
          size = null;
        };

        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };

        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };

        gtk3 = {
          bookmarks = [ ];
          inherit extraConfig;
        };

        gtk4 = { inherit extraConfig; };
      };
    };
}
