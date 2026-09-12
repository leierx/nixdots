# Keyboard, locale and time. One decision, applied to the console, to X/xkb
# and to the wayland session.
let
  layout = "no";
  variant = "nodeadkeys";
in
{
  flake.modules.nixos.locale =
    { pkgs, ... }:
    {
      console = {
        earlySetup = true;
        keyMap = layout;
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
        inherit layout variant;
      };
    };

  flake.modules.homeManager.locale = {
    wayland.windowManager.hyprland.settings.config.input = {
      kb_layout = layout;
      kb_variant = variant;
    };
  };
}
