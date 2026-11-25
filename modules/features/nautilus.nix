{
  flake.modules.nixos.nautilus =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        nautilus
        # GNOME's own thumbnailers; Papers brings the PDF one
        glycin-thumbnailer
        gst-thumbnailers
        gnome-epub-thumbnailer
      ];
      services.gnome.sushi.enable = true;
      services.gnome.localsearch.enable = true;
      # the indexer runs only where XDG_SESSION_CLASS reached the user manager, as gnome-session does
      systemd.user.services.localsearch-3.unitConfig.ConditionEnvironment = "";
      services.gvfs.enable = true;

      xdg.mime.defaultApplications."inode/directory" = "org.gnome.Nautilus.desktop";

      # file dialogs are Nautilus too; everything else stays Hyprland's portal and GTK's
      xdg.portal = {
        extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
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

    wayland.windowManager.hyprland.settings.window_rule = [
      {
        match.class = "^org\\.gnome\\.NautilusPreviewer$";
        # Sushi 50 is GTK3, whose xdg-foreign v1 Hyprland lacks, so it comes without a parent and tiles
        float = true;
        center = true;
        # as on GNOME: the keys stay with Nautilus, whose selection it follows and whose Space closes it; it asks for focus on each file
        no_initial_focus = true;
        focus_on_activate = false;
      }
    ];
  };
}
