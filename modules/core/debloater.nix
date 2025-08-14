{ config, lib, ... }:
let
  cfg = config.dots.core.debloater;
in
{
  options.dots.core.debloater = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "debloat default nixos";
    };
  };

  config = lib.mkIf cfg.enable {
    documentation.nixos.enable = false;

    programs.nano.enable = false;
    programs.command-not-found.enable = false;

    networking.dhcpcd.enable = false;
  };
}
