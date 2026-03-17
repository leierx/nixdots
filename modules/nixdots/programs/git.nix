{
  lib,
  config,
  ...
}:
let
  cfg = config.nixdots.programs.git;
in
{
  options.nixdots.programs.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable nixdots.programs.git";
    };

    enableDefaultConfig = lib.mkEnableOption "nixdots.programs.git";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # default config
      (lib.mkIf cfg.enableDefaultConfig {
        home-manager.users.leier = {
          programs.git.includes = [
            {
              condition = "hasconfig:remote.*.url:git@github.com:**/**";
              contents = {
                user = {
                  name = "leierx";
                  email = "larssmitheier@protonmail.com";
                };
              };
            }
          ];
        };
      })
    ]
  );
}
