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

        imports = [
          flakeInputs.self.homeManagerModules.neovim
          ../../modules/home-manager/desktops/hyprland
          ../../modules/home-manager/git.nix
          ../../modules/home-manager/gui/base
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
    ../../modules/nixos/core/nixos-settings.nix
    ../../modules/nixos/core/primary-user.nix
    ../../modules/nixos/core/privilege-escalation/doas.nix
    # desktop
    ../../modules/nixos/desktops/hyprland.nix
    ../../modules/nixos/gui/audio.nix
    ../../modules/nixos/gui/fonts.nix
    ../../modules/nixos/overlays/vesktop.nix
    ../../modules/nixos/services/display-manager.nix
    ./monitors.nix
  ];
}
