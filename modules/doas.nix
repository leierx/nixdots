{ self, ... }:
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
    };
}
