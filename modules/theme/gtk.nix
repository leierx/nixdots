root@{ lib, ... }:
let
  adw = root.config.palettes.adwaita_darker;
  surfaces = [
    "window_bg_color"
    "view_bg_color"
    "headerbar_bg_color"
    "headerbar_backdrop_color"
    "sidebar_bg_color"
    "sidebar_backdrop_color"
    "secondary_sidebar_bg_color"
    "secondary_sidebar_backdrop_color"
    "overview_bg_color"
    "thumbnail_bg_color"
    "dialog_bg_color"
    "popover_bg_color"
  ];
in
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
        # on Wayland GTK takes gtk-recent-files-enabled from here, over settings.ini
        "org/gnome/desktop/privacy".remember-recent-files = false;
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
          # adw-gtk3 takes libadwaita's named colours, less those it never reads
          extraCss = lib.concatMapStrings (name: "@define-color ${name} ${adw.${name}};\n") (
            lib.subtractLists [
              "secondary_sidebar_bg_color"
              "secondary_sidebar_backdrop_color"
              "overview_bg_color"
              "thumbnail_bg_color"
            ] surfaces
          );
        };

        gtk4 = {
          inherit extraConfig;
          extraCss = ''
            @media (prefers-color-scheme: dark) {
              :root {
            ${
              lib.concatMapStrings (
                name: "    --${lib.replaceStrings [ "_" ] [ "-" ] name}: ${adw.${name}};\n"
              ) surfaces
            }  }
            }
          '';
        };
      };
    };
}
