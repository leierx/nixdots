{ flakeInputs, pkgs, config, ... }:
{
  config = {
    # hardware
    hardware.enableAllFirmware = true;
    hardware.keyboard.zsa.enable = true;

    # GAMING
    programs.steam.enable = true;
    hardware.steam-hardware.enable = true; # udev rules for controllers etc

    # wireguard
    networking.firewall.checkReversePath = false;

    environment.systemPackages = with pkgs; [
      kubectl kubie kubectl-df-pv # kubernetes utils
      xfce.mousepad # notepad
      spotify # music
      pavucontrol # settings gui apps
      brave firefox-bin # browsers
      pika-backup # home directory file backup
      keymapp # zsa keyboard mapper
      wireguard-tools age opentofu sops # server dev
      tree fzf fastfetch # cli tools
      vesktop signal-desktop # communication apps
      meld # compare text files
      obsidian  # note taking
      valent # KDE-connect implementation in GTK
    ];

    # home-manager
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      extraSpecialArgs = { inherit flakeInputs; };
      users.${config.dots.nixos.core.primaryUser.username} = {
        home.stateVersion = config.system.stateVersion;

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
        dots.homeManager.gui.base.cursor.size = 32;

        wayland.windowManager.hyprland.settings = {
          exec-once = [ "vesktop" ]; windowrulev2 = [ "monitor DP-2, class:^(vesktop)$" ];
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

        imports = [
          flakeInputs.self.homeManagerModules.neovim
          ../../modules/home-manager/desktops/base
          ../../modules/home-manager/desktops/hyprland
          ../../modules/home-manager/git.nix
          ../../modules/home-manager/tmux.nix
          ../../modules/home-manager/zsh.nix
        ];
      };
    };
    users.users.${config.dots.nixos.core.primaryUser.username}.shell = pkgs.zsh; # ZSH
    programs.zsh.enable = true;
  };

  imports = [
    # hardware
    flakeInputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    flakeInputs.nixos-hardware.nixosModules.common-gpu-amd
    flakeInputs.nixos-hardware.nixosModules.common-pc-ssd

    # core system
    ../../modules/nixos/core/boot/grub.nix
    ../../modules/nixos/core/boot/plymouth.nix
    ../../modules/nixos/core/locale.nix
    ../../modules/nixos/core/network/network-manager.nix
    ../../modules/nixos/core/nixos.nix
    ../../modules/nixos/core/primary-user.nix
    ../../modules/nixos/core/privilege-escalation/doas.nix
    # desktop
    ../../modules/nixos/desktops/hyprland.nix
    ../../modules/nixos/graphical
    ../../modules/nixos/overlays/vesktop.nix
    ../../modules/nixos/graphical/display-manager.nix
    ./disko.nix
    ./monitors.nix
  ];
}
