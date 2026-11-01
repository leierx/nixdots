root: {
  flake.modules.homeManager.hyprland =
    {
      config,
      pkgs,
      ...
    }:
    let
      colors = root.config.palettes.ui;

      # D-Bus activates mako.service instead of a bare mako, so the drop-in below applies
      mako = pkgs.symlinkJoin {
        name = "mako-systemd";
        paths = [ pkgs.mako ];
        postBuild = ''
          f=share/dbus-1/services/fr.emersion.mako.service
          rm $out/$f
          sed '$a SystemdService=mako.service' ${pkgs.mako}/$f >$out/$f
        '';
      };
    in
    {
      # dependencies
      home.packages = [ pkgs.hack-font ];

      # notifications never start mako outside Hyprland
      xdg.configFile."systemd/user/mako.service.d/hyprland.conf".text = ''
        [Unit]
        Requisite=${config.wayland.systemd.target}
      '';

      services.mako = {
        enable = true;
        package = mako;
        settings = {
          # ── Binding options ─────────────────────────────────────────────
          on-button-left = "invoke-default-action";
          on-button-middle = "none";
          on-button-right = "dismiss";
          on-touch = "dismiss";
          # ── Style options ───────────────────────────────────────────────
          font = "Hack 12";
          background-color = colors.bg1;
          text-color = colors.fg;
          width = 500;
          height = 150; # max popup height in px (shrinks to fit)
          outer-margin = 10; # margin outside the whole notification list
          margin = "10,0"; # margin around each individual notification
          padding = 20; # inner padding on each side
          border-size = 2;
          border-color = colors.primaryColor; # border color
          border-radius = 10;
          progress-color = "over ${colors.bg3}"; # progress indicator: "over" overlays, "source" replaces bg
          icons = true;
          icon-path = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";
          history = true;
          format = ''<b>%s</b>\n%b''; # notification format string (grouped default: (%g) <b>%s</b>\n%b)
          default-timeout = 20000;
          ignore-timeout = true; # ignore app-sent expire timeout, use default-timeout
          max-visible = 8; # max visible notifications (-1 = unlimited)
        };
      };
    };
}
