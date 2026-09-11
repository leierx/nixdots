{
  flake.modules.nixos.core = {
    documentation.nixos.enable = false;
    networking.dhcpcd.enable = false;

    programs.nano.enable = false;
    programs.neovim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
    };
  };
}
