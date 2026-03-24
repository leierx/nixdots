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
    # nixdots custom module
    "${inputs.self}/modules/nixdots"
    # extra config files
    ./disko.nix
  ];

  config = {
    # nixdots
    nixdots.base.network.dot.enable = true;
    nixdots.gui.base.cursor.size = 32;
    nixdots.gui.desktops.hyprland.enable = true;
    nixdots.gui.desktops.hyprland.hyprdynamicmonitors = {
      profiles."dual_monitor.go.tmpl" = ''
        {{- $right := index .MonitorsByTag "right" -}}
        {{- $left := index .MonitorsByTag "left" -}}
        monitor = {{$right.Name}},2560x1440@144,auto-right,1
        monitor = {{$left.Name}},2560x1440@144,auto-left,1
      '';
      extraConfig = ''
        [profiles.dual_monitor]
        config_file = "hyprconfigs/dual_monitor.go.tmpl"
        config_file_type = "template"
        [[profiles.dual_monitor.conditions.required_monitors]]
        description = "AOC Q27G2G4 0x000021BD"
        monitor_tag = "right"
        [[profiles.dual_monitor.conditions.required_monitors]]
        description = "AOC Q27G2G4 0x000023BD"
        monitor_tag = "left"
      '';
    };
    nixdots.gui.enable = true;
    nixdots.programs.git.enableDefaultConfig = true;
    nixdots.programs.tmux.enable = true;
    nixdots.services.incus.enable = true;
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
      gthumb
      dolphin-emu
      opencode
    ];

    services.udev.packages = with pkgs; [ dolphin-emu ];

    home-manager.users.leier = {
      imports = [ inputs.neovim-config.homeManagerModules.default ];

      neovimDots = {
        useOutOfStore = true;
        outOfStorePath = "/home/leier/Projects/nixdots/modules/home-manager/neovim";
      };

      wayland.windowManager.hyprland.settings = {
        exec-once = [ "vesktop [monitor DP-2]" ];
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
