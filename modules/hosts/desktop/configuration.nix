{
  flake.modules.nixos."nixosConfigurations/desktop" =
    { pkgs, ... }:
    {
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
