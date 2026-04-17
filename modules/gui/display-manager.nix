{
  flake.modules.nixos.displayManager =
    { lib, config, ... }:
    let
      cfg = config.flakeModules.displayManager;
    in
    {
      options.flakeModules.displayManager = {
        implementation = lib.mkOption {
          type = lib.types.enum [
            "ly"
            "gdm"
          ];
          default = "ly";
          description = "Which display manager implementation to use";
        };
      };

      config = {
        services.displayManager.ly = lib.mkIf (cfg.implementation == "ly") {
          enable = true;
          settings = {
            allow_empty_password = false;
            clear_password = true;
            session_log = "null";
          };
        };

        services.displayManager.gdm = lib.mkIf (cfg.implementation == "gdm") {
          enable = true;
          wayland = true;
          autoSuspend = false;
          settings = { };
        };
      };
    };
}
