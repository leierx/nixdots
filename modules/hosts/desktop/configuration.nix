{ config, ... }:
{
  modules.nixos.hosts.desktop =
    { pkgs, ... }:
    {
      imports = [
        config.modules.nixos.profiles.minimal
        config.modules.nixos.profiles.graphical
        config.modules.nixos.gaming
      ];

      # wireguard
      networking.firewall.checkReversePath = false;

      home-manager.sharedModules = [
        {
          wayland.windowManager.hyprland.settings = {
            exec-once = [ "vesktop" ];
            windowrulev2 = [ "workspace 6 silent, class:^([Vv]esktop)$" ];
          };

          programs.ssh = {
            enable = true;
            matchBlocks = {
              "github.com" = {
                hostname = "github.com";
                user = "git";
                identityFile = [ "~/.ssh/id_ed25519" ];
              };
              "*.rsync.net" = {
                identityFile = [ "~/.ssh/id_rsync_net" ];
                identitiesOnly = true;
              };
            };
          };
        }
      ];

      environment.systemPackages = with pkgs; [
        kubectl
        kubectl-df-pv
        xfce.mousepad
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
        vesktop
        opencode
      ];
    };
}
