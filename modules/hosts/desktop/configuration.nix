{
  flake.modules.nixos."nixosConfigurations/desktop" =
    { pkgs, ... }:
    {
      # stateful services key their data formats off this; never bump it with nixpkgs
      system.stateVersion = "26.05";

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
