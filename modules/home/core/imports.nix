{ config, ... }:
{
  flake.modules.homeManager.core.imports = with config.flake.modules.homeManager; [
    git
    locale
    opencode
    tmux
    xdg-user-dirs
    zsh
  ];
}
