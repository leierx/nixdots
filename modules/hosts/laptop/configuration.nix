{ self, ... }:
{
  configurations.nixos.laptop =
    { pkgs, ... }:
    {
      imports = [
        self.modules.nixos.profileMinimal
      ];

      environment.systemPackages = with pkgs; [
        xfce.mousepad
        spotify
        pavucontrol
        brave
        firefox-bin
        obsidian
        vesktop # discord client
        opencode
        treefmt
        bitwarden-cli
      ];
    };
}
