{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.core.locale;
in
{
  options.nixdots.core.locale = {
    enable = lib.mkEnableOption "Enable locale + console + time defaults";
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
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      # US English for wording and text
      LC_MESSAGES = "en_US.UTF-8";
      LC_RESPONSE = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_COLLATE = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";

      # Norwegian for numeric, date, and measurement formatting
      LC_NUMERIC = "nb_NO.UTF-8";
      LC_TIME = "nb_NO.UTF-8";
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
