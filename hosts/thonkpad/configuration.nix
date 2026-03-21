{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    # hardware
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14-intel-gen6
    # nixdots custom module
    "${inputs.self}/modules/nixdots"
    # extra config files
    ./disko.nix
  ];

  config = {
    # nixdots
    nixdots.base.network.dot.enable = true;
    nixdots.gui.desktops.hyprland.enable = true;
    nixdots.gui.enable = true;
    nixdots.programs.git.enableDefaultConfig = true;
    nixdots.programs.tmux.enable = true;
    nixdots.services.podman.enable = true;
    nixdots.services.incus.enable = true;

    # fast as fuck boot
    boot.loader.timeout = lib.mkForce 0;
    nixdots.base.bootloader.implementation = "systemd-boot";

    # hardware
    hardware.enableAllFirmware = true;

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

    home-manager.users.leier = {
      imports = [ inputs.neovim-config.homeManagerModules.default ];

      wayland.windowManager.hyprland.settings = {
        exec-once = [
          "vesktop [workspace 1 silent]"
          "$terminal [workspace 2 silent]"
        ];
      };
    };
  };
}
