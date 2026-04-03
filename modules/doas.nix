{ config, ... }:
let
  wheelNeedsPassword = config.flake.meta.security.wheelNeedsPassword;
in
{
  flake.modules.nixos.doas =
    { lib, pkgs, ... }:
    {
      config = {
        security.doas = {
          enable = true;
          extraRules = [
            {
              groups = [ "wheel" ];
              keepEnv = true;
              noPass = lib.mkDefault (!wheelNeedsPassword);
              persist = lib.mkDefault wheelNeedsPassword;
            }
          ];
        };
        security.sudo.enable = false;

        environment = {
          interactiveShellInit = ''alias sudo="doas"'';
          systemPackages = [ pkgs.doas-sudo-shim ];
        };
      };
    };
}
