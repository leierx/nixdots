{
  lib,
  config,
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
    home-manager.users.${config.nixdots.core.primaryUser.username}.imports = [ flakeInputs.neovim-dotfiles.homeManagerModules.default ];
  };
}
