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

    # locale
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "nb_NO.UTF-8"; # regional address format
      LC_IDENTIFICATION = "nb_NO.UTF-8";
      LC_MEASUREMENT = "nb_NO.UTF-8"; # metric system (kg, °C)
      LC_MONETARY = "nb_NO.UTF-8"; # NOK currency
      LC_NAME = "nb_NO.UTF-8";
      LC_PAPER = "nb_NO.UTF-8"; # A4
      LC_TELEPHONE = "nb_NO.UTF-8";
      #
      LC_MESSAGES = "en_US.UTF-8"; # CLI output, manpages (no "colour")
      LC_CTYPE = "en_US.UTF-8"; # must match LANG
      LC_COLLATE = "en_US.UTF-8"; # sort order
      LC_NUMERIC = "en_US.UTF-8"; # decimal point (`.`), thousands sep
      LC_TIME = "en_GB.UTF-8"; # 24h time, ISO dates, still English month names
    };

    # xserver defaults
    services.xserver.xkb.variant = "nodeadkeys";
    services.xserver.xkb.layout = "no";
  };
}
