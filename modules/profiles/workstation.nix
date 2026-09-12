# A machine I sit in front of: display manager, audio, the wayland session
# and the graphical tooling that goes with them.
top: {
  flake.modules.nixos.workstation = {
    imports = with top.config.flake.modules.nixos; [
      display-manager
      fonts
      gtk
      hyprland
      plymouth
      sound
    ];

    home-manager.users.${top.config.identity.username}.imports = [
      top.config.flake.modules.homeManager.workstation
    ];
  };

  flake.modules.homeManager.workstation.imports = with top.config.flake.modules.homeManager; [
    cursor
    gtk
    hyprland
    neovim
    qt
    rofi
    wezterm
  ];
}
