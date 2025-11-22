{ config, pkgs, lib, ... }:
{
  options.dots.nixos.core.doas.requirePasswordForWheel = lib.mkEnableOption "";

  config = {
    security.doas.enable = true;
    security.sudo.enable = false;

    environment.interactiveShellInit = ''alias sudo="doas"'';

    # some programs depend on a shim
    environment.systemPackages = with pkgs; [ doas-sudo-shim ];

    environment.etc."doas.conf".text = lib.mkForce ''
      permit ${if config.dots.nixos.core.doas.requirePasswordForWheel then "persist" else "nopass"} keepenv :wheel
      permit nopass keepenv root
    '';
  };
}
