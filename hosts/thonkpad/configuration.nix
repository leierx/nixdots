{
  inputs,
  pkgs,
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
    ];

    home-manager.users.leier = {
      imports = [ inputs.self.homeManagerModules.neovim ];

      wayland.windowManager.hyprland.settings = {
        exec-once = [ "vesktop" ];
        windowrulev2 = [ "monitor DP-2, class:^(vesktop)$" ];
      };
    };
  };
}
