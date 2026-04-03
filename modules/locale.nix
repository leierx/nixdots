{ self, ... }:
{
  flake.modules.nixos.locale =
    { pkgs, ... }:
    {
      console = {
        earlySetup = true;
        keyMap = "no";
        font = "${pkgs.terminus_font}/share/consolefonts/ter-i20b.psf.gz";
      };

      time.timeZone = "Europe/Oslo";

      services.timesyncd = {
        enable = true;
        servers = [
          "0.no.pool.ntp.org"
          "1.no.pool.ntp.org"
          "2.no.pool.ntp.org"
          "3.no.pool.ntp.org"
        ];
      };

      i18n.defaultLocale = "en_DK.UTF-8";

      services.xserver.xkb = {
        layout = "no";
        variant = "nodeadkeys";
      };

      home-manager.sharedModules = [ self.modules.homeManager.locale ];
    };

  flake.modules.homeManager.locale = {
    wayland.windowManager.hyprland = {
      settings = {
        input = {
          kb_layout = "no";
          kb_variant = "nodeadkeys";
        };
      };
    };
  };
}
