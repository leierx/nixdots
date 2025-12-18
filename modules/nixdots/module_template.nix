{ lib, config, ... }:
let
  cfg = config.nixdots.module;
in
{
  options.nixdots.module = {
    enable = lib.mkEnableOption "Enable";

    implementation = lib.mkOption {
      type = lib.types.enum [ ];
      default = "";
      description = "";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # common config goes here
      }

      (lib.mkIf (cfg.implementation == "") {
        # implementation A config
      })

      (lib.mkIf (cfg.implementation == "") {
        # implementation B config
      })
    ]
  );
}
