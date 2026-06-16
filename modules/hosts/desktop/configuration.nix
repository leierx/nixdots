{ config, ... }:
{
  modules.nixos.hosts.desktop =
    { pkgs, lib, ... }:
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

          wayland.windowManager.hyprland = {
            settings = {
              window_rule = [
                {
                  match.class = "^(discord-canary)$";
                  monitor = "DP-2";
                  no_initial_focus = true;
                }
              ];
              on = [
                {
                  _args = [
                    "hyprland.start"
                    (lib.generators.mkLuaInline ''function() hl.exec_cmd("${pkgs.discord-canary}/bin/discordcanary") end'')
                  ];
                }
                {
                  _args = [
                    "hyprland.start"
                    (lib.generators.mkLuaInline ''function() hl.exec_cmd("${pkgs.firefox-bin}/bin/firefox", {monitor = "DP-1"}) end'')
                  ];
                }
              ];
            };
          };
        }
      ];

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
        opencode
        discord-canary
      ];
    };
}
