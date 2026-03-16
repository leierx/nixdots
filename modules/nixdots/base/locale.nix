{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.base.locale;
in
{
  options.nixdots.base.locale = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable nixdots.base.locale";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure console keymap & font
    console = {
      earlySetup = true;
      keyMap = "no";
      font = "${pkgs.terminus_font}/share/consolefonts/ter-i20b.psf.gz";
    };

    # timezone
    time.timeZone = "Europe/Oslo";

    # NTP
    services.timesyncd = {
      enable = true;
      servers = [
        "0.no.pool.ntp.org"
        "1.no.pool.ntp.org"
        "2.no.pool.ntp.org"
        "3.no.pool.ntp.org"
      ];
    };

    # locale
    i18n.defaultLocale = "en_DK.UTF-8";

    # xserver defaults
    services.xserver.xkb.variant = "nodeadkeys";
    services.xserver.xkb.layout = "no";
  };
}
