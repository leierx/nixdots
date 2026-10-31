{
  flake.modules.nixos."nixosConfigurations/desktop" =
    { pkgs, ... }:
    {
      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true; # needed for KMS screen capture on Wayland
        openFirewall = true;
      };

      environment.systemPackages = with pkgs; [
        kubectl-df-pv
        pika-backup
        keymapp
        wireguard-tools
        age
        opentofu
        sops
        signal-desktop
        meld
        gimp
        unstable.openmw
      ];
    };
}
