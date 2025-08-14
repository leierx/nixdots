{ config, lib, pkgs, ... }:

let
  cfg = config.dots.core.privilegeEscalation;
in
{
  options.dots.core.privilegeEscalation = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "privilege escalation support via doas or sudo";
    };

    implementation = lib.mkOption {
      type = lib.types.enum [ "sudo" "doas" ];
      default = "doas";
      description = "Privilege escalation backend to use.";
    };

    noPasswordForWheel = lib.mkEnableOption "allow passwordless privilege escalation for users in the wheel group";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      security.polkit.enable = true;
    }

    (lib.mkIf (cfg.implementation == "doas") {
      security.doas.enable = true;
      security.sudo.enable = false;

      environment.etc."doas.conf".text = lib.mkForce ''
        permit ${if cfg.noPasswordForWheel then "nopass" else "persist"} keepenv setenv { SSH_AUTH_SOCK TERMINFO TERMINFO_DIRS } :wheel
        permit nopass keepenv root
      '';

      environment.interactiveShellInit = ''alias sudo="doas"'';
    })

    (lib.mkIf (cfg.implementation == "sudo") {
      security.sudo = {
        enable = true;
        wheelNeedsPassword = !cfg.noPasswordForWheel;
      };

      security.doas.enable = false;
    })
  ]);
}
