{
  flake.modules.nixos."nixosConfigurations/desktop" =
    { pkgs, ... }:
    {
      # wireguard
      networking.firewall.checkReversePath = false;

      environment.systemPackages = with pkgs; [
        kubectl
        kubectl-df-pv
        mousepad
        spotify
        pavucontrol
        brave
        firefox-bin
        pika-backup
        keymapp
        wireguard-tools
        age
        opentofu
        sops
        signal-desktop
        meld
        obsidian
        gimp
        discord-canary
        unstable.openmw
      ];
    };
}
