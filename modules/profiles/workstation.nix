# A machine I sit in front of: display manager, audio, the wayland session
# and the graphical tooling that goes with them.
root: {
  flake.modules.nixos.workstation = {
    imports = with root.config.flake.modules.nixos; [
      display-manager
      fonts
      gtk
      hyprland
      plymouth
      sound
    ];

    home-manager.users.${root.config.identity.username}.imports = [
      root.config.flake.modules.homeManager.workstation
    ];
  };

  flake.modules.homeManager.workstation.imports = with root.config.flake.modules.homeManager; [
    cursor
    gtk
    hyprland
    neovim
    qt
    rofi
    kitty
  ];
}
