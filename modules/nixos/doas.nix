{ self, ... }:
{
  flake.modules.nixos.doas =
    { config, pkgs, ... }:
    {
      security = {
        enable = true;
        extraRules = [
          {
            groups = [ "wheel" ];
            keepEnv = true;
            noPass = !self.settings.security.wheelNeedsPassword;
            persist = self.settings.security.wheelNeedsPassword;
          }
        ];
        sudo.enable = false;
      };

      environment = {
        interactiveShellInit = ''alias sudo="doas"'';
        systemPackages = [ pkgs.doas-sudo-shim ];
      };

      assertions = [
        {
          assertion = !(config.security.sudo.enable or false);
          message = "flake.modules.nixos.doas requires security.sudo.enable = false";
        }
      ];
    };
}
