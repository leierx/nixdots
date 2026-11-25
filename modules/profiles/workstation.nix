root: {
  flake.modules.nixos.workstation = {
    imports = with root.config.flake.modules.nixos; [
      display-manager
      fonts
      gtk
      hyprland
      nautilus
      plymouth
      sound
    ];

    home-manager.users.${root.config.identity.username}.imports = [
      root.config.flake.modules.homeManager.workstation
    ];
  };

  flake.modules.homeManager.workstation.imports = with root.config.flake.modules.homeManager; [
    bluetooth
    cursor
    desktop-apps
    gtk
    hyprland
    nautilus
    neovim
    qt
    wezterm
  ];
}
