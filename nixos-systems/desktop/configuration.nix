{
  flakeInputs,
  pkgs,
  config,
  ...
}:
{
  imports = [
    # hardware
    flakeInputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    flakeInputs.nixos-hardware.nixosModules.common-gpu-amd
    flakeInputs.nixos-hardware.nixosModules.common-pc-ssd
    #
    ./disko.nix
    ./monitors.nix
  ];

  config = {
    # nixdots
    nixdots.enableCore = true;
    nixdots.enableGraphicalSystem = true;
    nixdots.overlays.vesktopDiscordAlias.enable = true;
    nixdots.programs.neovim.enable = true;
    config.nixdots.programs.tmux = true;
    nixdots.graphical.desktops.hyprland.enable = true;
    nixdots.core.network.dot.enable = true; # DNS over TLS
    nixdots.graphical.base.cursor.size = 32; # Scaling

    # hardware
    hardware.enableAllFirmware = true;
    hardware.keyboard.zsa.enable = true;
    # boot.kernelModules = [ "mt7921e" ]; #wifi card

    # GAMING
    programs.steam.enable = true;
    hardware.steam-hardware.enable = true; # udev rules for controllers etc

    # wireguard
    networking.firewall.checkReversePath = false;

    environment.systemPackages =
      (with pkgs; [
        kubectl
        kubie
        kubectl-df-pv # kubernetes utils
        xfce.mousepad # notepad
        spotify # music
        pavucontrol # settings gui apps
        brave
        firefox-bin # browsers
        pika-backup # home directory file backup
        keymapp # zsa keyboard mapper
        wireguard-tools
        age
        opentofu
        sops # server dev
        tree
        fzf
        fastfetch # cli tools
        signal-desktop # communication apps
        meld # compare text files
        obsidian # note taking
        valent # KDE-connect implementation in GTK
      ])
      ++ builtins.attrValues flakeInputs.self.packages.${pkgs.stdenv.hostPlatform.system};

    home-manager.users.${config.nixdots.core.primaryUser.username} = {
      programs.git.includes = [
        {
          condition = "hasconfig:remote.*.url:git@github.com:**/**";
          contents = {
            user = {
              name = "leierx";
              email = "larssmitheier@protonmail.com";
            };
          };
        }
      ];

      # Scaling
      dconf.settings."org/gnome/desktop/interface".text-scaling-factor = 1.1;

      wayland.windowManager.hyprland.settings = {
        exec-once = [ "vesktop" ];
        windowrulev2 = [ "monitor DP-2, class:^(vesktop)$" ];
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
    };
  };
}
