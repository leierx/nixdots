# The baseline every machine of mine gets. Hosts import it explicitly; the
# builders inject nothing.
top: {
  flake.modules.nixos.base = {
    imports = with top.config.flake.modules.nixos; [
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

    home-manager.users.${top.config.identity.username}.imports = [
      top.config.flake.modules.homeManager.base
    ];
  };

  flake.modules.darwin.base = {
    imports = with top.config.flake.modules.darwin; [
      home-manager
      nixpkgs
    ];

    home-manager.users.${top.config.identity.username}.imports = [
      top.config.flake.modules.homeManager.base
    ];
  };

  flake.modules.homeManager.base.imports = with top.config.flake.modules.homeManager; [
    git
    locale
    opencode
    tmux
    users
    xdg-user-dirs
    zsh
  ];
}
