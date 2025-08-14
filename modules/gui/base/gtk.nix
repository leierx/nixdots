{ config, pkgs, lib, ... }:
let
  cfg = config.dots.gui.gtk;
in
{
  options.dots.gui.gtk.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.dots.gui.enable;
  };

  config = lib.mkIf cfg.enable {
    # dependencies
    programs.dconf.enable = true;

    home-manager.sharedModules = [
      ({ ... }@homeManagerInputs: {
        gtk = {
          enable = true;

          # denne er skummel å leke med. Driter i size og setter en classic gnome default font her.
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
            bookmarks = [ ]; # for GTK file browsers mainly
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
        dconf = { settings."org/gnome/desktop/interface".color-scheme = "prefer-dark"; }; # GTK4
      })
    ];
  };
}
