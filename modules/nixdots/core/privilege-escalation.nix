{ lib, config, ... }:
let
  cfg = config.nixdots.core.privilegeEscalation;
in
{
  options.nixdots.core.privilegeEscalation = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable nixdots.core.privilegeEscalation";
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
