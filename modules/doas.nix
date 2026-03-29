{ config, ... }:
{
  flake.modules.nixos.doas =
    { pkgs, ... }:
    {
      security = {
        enable = true;
        extraRules = [
          {
            groups = [ "wheel" ];
            keepEnv = true;
            noPass = !config.settings.security.wheelNeedsPassword;
            persist = config.settings.security.wheelNeedsPassword;
          }
        ];
        sudo.enable = false;
      };

      environment = {
        interactiveShellInit = ''alias sudo="doas"'';
        systemPackages = [ pkgs.doas-sudo-shim ];
      };
    };
}
