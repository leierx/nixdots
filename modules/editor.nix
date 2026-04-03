{
  flake.modules.nixos.editor = {
    programs.nano.enable = false;
    programs.neovim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
    };
  };
}
