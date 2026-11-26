{
  flake.modules.nixos.nautilus =
    { pkgs, ... }:
    let
      # GNOME 51: Sushi on GTK4 attaches to Nautilus and floats by itself; back to pkgs and services.gnome.{sushi,localsearch} once NixOS 26.11 is out
      inherit (pkgs.unstable) nautilus sushi localsearch;
    in
    {
      environment.systemPackages = [
        nautilus
        sushi
        localsearch
        # GNOME's own thumbnailers; Papers brings the PDF one
        pkgs.glycin-thumbnailer
        pkgs.gst-thumbnailers
        pkgs.gnome-epub-thumbnailer
      ];
      services.dbus.packages = [
        sushi
        localsearch
      ];
      systemd.packages = [ localsearch ];
      # the indexer runs only where XDG_SESSION_CLASS reached the user manager, as gnome-session does
      systemd.user.services.localsearch-3.unitConfig.ConditionEnvironment = "";
      services.gvfs.enable = true;

      xdg.mime.defaultApplications."inode/directory" = "org.gnome.Nautilus.desktop";

      # file dialogs are Nautilus too; everything else stays Hyprland's portal and GTK's
      xdg.portal = {
        extraPortals = [ pkgs.unstable.xdg-desktop-portal-gnome ];
        config.hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gnome" ];
        };
      };
    };

  flake.modules.homeManager.nautilus = {
    dconf.settings."org/gnome/nautilus/preferences" = {
      show-create-link = true;
      show-delete-permanently = true;
    };

    # the keys stay with Nautilus, whose selection Sushi follows and whose Space closes it; it asks for focus on each file
    wayland.windowManager.hyprland.settings.window_rule = [
      {
        match.class = "^org\\.gnome\\.NautilusPreviewer$";
        no_initial_focus = true;
        focus_on_activate = false;
      }
    ];
  };
}
