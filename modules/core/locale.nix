{ config, lib, pkgs, ... }:
let
  cfg = config.dots.core.locale;
in
{
  options.dots.core.locale.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "system locale settings (LANG, LC_*, keymap, console font)";
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
    i18n.defaultLocale = "en_GB.UTF-8";
    i18n.extraLocaleSettings = {
      # English for UI text and tool behavior
      LC_MESSAGES = "en_GB.UTF-8";
      LC_RESPONSE = "en_GB.UTF-8";
      LC_TIME = "en_GB.UTF-8";
      LC_NUMERIC = "en_GB.UTF-8";
      LC_COLLATE = "en_GB.UTF-8";
      LC_CTYPE = "en_GB.UTF-8";
      LC_NAME = "en_GB.UTF-8";

      # Norwegian for administrative and formatting categories
      LC_MONETARY = "nb_NO.UTF-8";
      LC_MEASUREMENT = "nb_NO.UTF-8";
      LC_PAPER = "nb_NO.UTF-8";
      LC_ADDRESS = "nb_NO.UTF-8";
      LC_TELEPHONE = "nb_NO.UTF-8";
      LC_IDENTIFICATION = "nb_NO.UTF-8";
    };

    # xserver defaults
    services.xserver.xkb.variant = "nodeadkeys";
    services.xserver.xkb.layout = "no";
  };
}
