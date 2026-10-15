# Formatting and evaluation checks, expressed through `perSystem`.
{ config, ... }:
{
  perSystem =
    { lib, pkgs, ... }:
    {
      formatter = pkgs.nixfmt-tree;

      checks = {
        format =
          pkgs.runCommand "nixfmt-check"
            {
              src = ../..;
              nativeBuildInputs = [ pkgs.nixfmt ];
            }
            ''
              find "$src" -name '*.nix' -type f -print0 | xargs -0 nixfmt --check
              touch "$out"
            '';
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        # instantiate every host and installer; the discarded context keeps them from being built
        eval =
          pkgs.runCommand "eval-check"
            {
              toplevelDrvs = builtins.map (
                system: builtins.unsafeDiscardStringContext system.config.system.build.toplevel.drvPath
              ) (builtins.attrValues config.flake.nixosConfigurations);
            }
            ''
              echo "$toplevelDrvs" > "$out"
            '';
      };
    };
}
