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
              # exported by doas-sudo-shim; git/libgit2 use SUDO_UID to trust the caller's repos
              "SUDO_UID"
              "SUDO_GID"
              "SUDO_USER"
            ];
          }
        ];
      };
      security.sudo.enable = false;

      environment.systemPackages = [ pkgs.doas-sudo-shim ];
    };
}
