{ lib, ... }:
{
  options.flake.settings.gui = with lib; {
    displayManager = mkOption {
      type = types.enum [
        "gdm"
        "ly"
      ];
      default = "ly";
    };
  };
}
