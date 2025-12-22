{
  lib,
  config,
  pkgs,
  flakeInputs,
  ...
}:
let
  cfg = config.nixdots.programs.neovim;
in
{
  options.nixdots.programs.neovim = {
    enable = lib.mkEnableOption "Enable neovim";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${config.nixdots.core.primaryUser.username}.xdg.configFile."nvim".source = flakeInputs.neovim-dotfiles;
  };
}
