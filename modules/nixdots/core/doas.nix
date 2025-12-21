{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.core.doas;
in
{
  options.nixdots.core.doas = {
    enable = lib.mkEnableOption "Enable doas (and disable sudo)";

    requirePasswordForWheel = lib.mkEnableOption "Require password for wheel via doas";
  };

  config = lib.mkIf cfg.enable {
    security.doas.enable = true;
    security.sudo.enable = false;

    # alias
    environment.interactiveShellInit = "alias sudo=\"doas\"";

    # some programs need on a shim
    environment.systemPackages = [ pkgs.doas-sudo-shim ];

    environment.etc."doas.conf".text = lib.mkForce ''
      permit ${if cfg.requirePasswordForWheel then "persist" else "nopass"} keepenv :wheel
      permit nopass keepenv root
    '';
  };
}
