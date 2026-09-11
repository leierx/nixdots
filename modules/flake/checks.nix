# Formatting and evaluation checks, expressed through `perSystem`.
{ config, ... }:
{
  perSystem =
    { pkgs, ... }:
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

        # Forces module-system evaluation of every NixOS host and installer
        # without building them: reading `.name` evaluates the derivation.
        eval =
          pkgs.runCommand "eval-check"
            {
              toplevelNames = builtins.map (system: system.config.system.build.toplevel.name) (
                builtins.attrValues config.flake.nixosConfigurations
              );
            }
            ''
              echo "$toplevelNames" > "$out"
            '';
      };
    };
}
