root: {
  flake.modules.nixos.base = {
    imports = with root.config.flake.modules.nixos; [
      boot
      doas
      documentation
      git
      home-manager
      journald
      locale
      network
      neovim
      nix
      nixpkgs
      oomd
      packages
      podman
      unstable-nixpkgs
      users
    ];

    home-manager.users.${root.config.identity.username}.imports = [
      root.config.flake.modules.homeManager.base
    ];
  };

  flake.modules.homeManager.base.imports = with root.config.flake.modules.homeManager; [
    documentation
    git
    pi-agent
    ssh
    tmux
    users
    xdg-user-dirs
    zsh
  ];
}
