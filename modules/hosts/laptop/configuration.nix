{ config, ... }:
{
  configurations.nixos.laptop =
    { pkgs, ... }:
    {
      imports = with config.flake.modules; [
        # profiles.nixos.graphical
        # nixos.hyprland
        nixos.bootloader
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

      home-manager.users.${config.flake.settings.user.username} = {
        imports = [
          # inputs.self.modules.homeManager.neovim
        ];
      };
    };
}
