{
  flake.modules.nixos.doas =
    { pkgs, ... }:
    {
      security.doas = {
        enable = true;
        extraRules = [
          {
            groups = [ "wheel" ];
            noPass = true;
            # keepenv would leak XDG_* and leave root-owned files in ~
            setEnv = [
              "LANG"
              "NIX_PATH"
            ];
          }
        ];
      };
      security.sudo.enable = false;

      environment.systemPackages = [ pkgs.doas-sudo-shim ];
    };
}
