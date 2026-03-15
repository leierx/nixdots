{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    # hardware
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    #
    ./disko.nix
    ./monitors.nix
  ];

  config = {
    # nixdots
    nixdots.core.network.dot.enable = true;
    nixdots.gui.base.cursor.size = true;
    nixdots.gui.desktops.hyprland.enable = true;
    nixdots.gui.enable = true;
    nixdots.programs.tmux.enable = true;
    nixdots.services.podman.enable = true;

    # hardware
    hardware.enableAllFirmware = true;
    hardware.keyboard.zsa.enable = true;
    # boot.kernelModules = [ "mt7921e" ]; #wifi card

    # GAMING
    programs.steam.enable = true;
    hardware.steam-hardware.enable = true; # udev rules for controllers etc

    # wireguard
    networking.firewall.checkReversePath = false;

    environment.systemPackages = with pkgs; [
      kubectl
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
      gimp
      vesktop # discord client
      gthumb
      dolphin-emu
      opencode
    ];

    services.udev.packages = with pkgs; [ dolphin-emu ];

    home-manager.users.leier = {
      imports = [ inputs.self.homeManagerModules.neovim ];

      neovimDots = {
        useOutOfStore = true;
        outOfStorePath = "/home/leier/Projects/nixdots/modules/home-manager/neovim";
      };

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
