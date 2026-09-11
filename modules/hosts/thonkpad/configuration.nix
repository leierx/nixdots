{
  nixpkgs.allowedUnfreePackages = [
    "discord-canary"
    "firefox-bin"
    "firefox-bin-unwrapped"
    "obsidian"
    "spotify"
  ];

  flake.modules.nixos."nixosConfigurations/thonkpad" =
    { pkgs, ... }:
    {
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
