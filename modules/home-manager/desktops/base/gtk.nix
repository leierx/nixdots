{ pkgs, ... }:
{
  gtk = {
    enable = true;

    font = {
      name = "gnome";
      package = pkgs.cantarell-fonts;
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
      bookmarks = []; # for GTK file browsers mainly
      extraConfig = {
        # dark theme - hell yea
        gtk-application-prefer-dark-theme = 1;
        #
        gtk-enable-animations = 1;
        gtk-enable-primary-paste = 0; # middle click on a mouse should paste the ‘PRIMARY’ clipboard
        gtk-recent-files-enabled = 0; # unnecessary
        # sound shit
        gtk-enable-event-sounds = 1;
        gtk-enable-input-feedback-sounds = 1;
        gtk-error-bell = 1;
      };
      extraCss = '''';
    };

    gtk4 = {
      extraConfig = {
        # dark theme - hell yea
        gtk-application-prefer-dark-theme = 1;
        #
        gtk-enable-animations = 1;
        gtk-enable-primary-paste = 0; # middle click on a mouse should paste the ‘PRIMARY’ clipboard
        gtk-recent-files-enabled = 0; # unnecessary
        # sound shit
        gtk-enable-event-sounds = 1;
        gtk-enable-input-feedback-sounds = 1;
        gtk-error-bell = 1;
      };
      extraCss = '''';
    };
  };
}
