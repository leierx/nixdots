{ flakeInputs, pkgs, lib, config, ... }:
{
  config = {
    # hardware
    hardware.enableAllFirmware = true;
    hardware.microsoft-surface.kernelVersion = "stable";

    # ZRAM to make oom killer happy
    zramSwap.enable = true;
    zramSwap.memoryPercent = 25;

    # iwd is tougher to work on surface
    networking.networkmanager.wifi.backend = lib.mkForce "wpa_supplicant";

    # use GDM, since I'm gonna be using gnome
    dots.nixos.services.displayManager.implementation = "gdm";

    environment.systemPackages = with pkgs; [
      xfce.mousepad # notepad
      spotify # music
      brave firefox-bin # browsers
      tree fzf fastfetch # cli tools
      vesktop signal-desktop # communication apps
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

        # Scaling
        dots.homeManager.gui.base.cursor.size = 24;

        imports = [
          flakeInputs.self.homeManagerModules.neovim
          ../../modules/home-manager/desktops/base
          ../../modules/home-manager/desktops/gnome.nix
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
    flakeInputs.nixos-hardware.nixosModules.microsoft-surface-common
    flakeInputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel

    # core system
    ../../modules/nixos/core/boot/grub.nix
    ../../modules/nixos/core/boot/plymouth.nix
    ../../modules/nixos/core/locale.nix
    ../../modules/nixos/core/network/network-manager.nix
    ../../modules/nixos/core/nixos.nix
    ../../modules/nixos/core/primary-user.nix
    ../../modules/nixos/core/privilege-escalation/doas.nix
    # desktop
    ../../modules/nixos/desktops/gnome.nix
    ../../modules/nixos/graphical/audio.nix
    ../../modules/nixos/graphical/fonts.nix
    ../../modules/nixos/overlays/vesktop.nix
    ../../modules/nixos/graphical/display-manager.nix
    ./disko.nix
  ];
}
