# The baseline every machine of mine gets. Hosts import it explicitly; the
# builders inject nothing.
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
      packages
      podman
      unstable-nixpkgs
      users
    ];

    home-manager.users.${root.config.identity.username}.imports = [
      root.config.flake.modules.homeManager.base
    ];
  };

  flake.modules.darwin.base = {
    imports = with root.config.flake.modules.darwin; [
      home-manager
      nixpkgs
    ];

    home-manager.users.${root.config.identity.username}.imports = [
      root.config.flake.modules.homeManager.base
    ];
  };

  flake.modules.homeManager.base.imports = with root.config.flake.modules.homeManager; [
    git
    locale
    opencode
    tmux
    users
    xdg-user-dirs
    zsh
  ];
}
