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
      # the popups' font
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
          on-button-left = "invoke-default-action";
          on-button-middle = "none";
          on-button-right = "dismiss";
          on-touch = "dismiss";
          font = "Hack 12";
          background-color = colors.bg1;
          text-color = colors.fg;
          width = 500;
          height = 150;
          outer-margin = 10;
          margin = "10,0";
          padding = 20;
          border-size = 2;
          border-color = colors.primaryColor;
          border-radius = 10;
          progress-color = "over ${colors.bg3}";
          icons = true;
          icon-path = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";
          history = true;
          format = ''<b>%s</b>\n%b'';
          default-timeout = 20000;
          ignore-timeout = true;
          max-visible = 8;
        };
      };
    };
}
