{
  flake.modules.nixos."nixosConfigurations/thonkpad" =
    { pkgs, ... }:
    {
      system.stateVersion = "26.05";

      # wireguard
      networking.firewall.checkReversePath = false;

      environment.systemPackages = with pkgs; [
        mousepad
        spotify
        pavucontrol
        brave
        firefox-bin
        obsidian
        treefmt
        discord-canary
        kubectl
      ];
    };
}
