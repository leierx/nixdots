{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.base.privilegeEscalation;
in
{
  options.nixdots.base.privilegeEscalation = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable nixdots.base.privilegeEscalation";
    };

    implementation = lib.mkOption {
      type = lib.types.enum [
        "doas"
        "sudo"
      ];
      default = "doas";
      description = "Which privilege escalation tool to configure";
    };

    wheelNeedsPassword = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the wheel group must enter a password when using sudo/doas";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (cfg.implementation == "doas") {
        security.doas = {
          enable = true;
          extraRules = [
            {
              groups = [ "wheel" ];
              keepEnv = true;
              noPass = !cfg.wheelNeedsPassword;
              persist = cfg.wheelNeedsPassword;
            }
          ];
        };

        security.sudo.enable = false;

        # alias + shim
        environment.interactiveShellInit = "alias sudo=\"doas\"";
        environment.systemPackages = [ pkgs.doas-sudo-shim ];
      })

      (lib.mkIf (cfg.implementation == "sudo") {
        security.sudo = {
          enable = true;
          wheelNeedsPassword = cfg.wheelNeedsPassword;
        };

        security.doas.enable = false;
      })
    ]
  );
}
