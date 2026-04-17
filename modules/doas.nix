{
  flake.modules.nixos.doas =
    { pkgs, ... }:
    {
      security.doas = {
        enable = true;
        extraRules = [
          {
            groups = [ "wheel" ];
            keepEnv = true;
            noPass = true;
          }
        ];
      };
      security.sudo.enable = false;

      environment = {
        interactiveShellInit = ''alias sudo="doas"'';
        systemPackages = [ pkgs.doas-sudo-shim ];
      };
    };
}
