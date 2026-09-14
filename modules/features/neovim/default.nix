root: {
  options.neovim.outOfStorePath = root.lib.mkOption {
    type = root.lib.types.nullOr root.lib.types.path;
    default = null;
    description = "Symlink the neovim config to this path instead of the store, for live editing";
  };

  config.flake.modules.nixos.neovim = {
    programs.neovim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
    };
    programs.nano.enable = false;
  };

  config.flake.modules.homeManager.neovim =
    { config, pkgs, ... }:
    {
      xdg.configFile."nvim".source =
        if root.config.neovim.outOfStorePath != null then
          config.lib.file.mkOutOfStoreSymlink root.config.neovim.outOfStorePath
        else
          ./assets;

      home.packages = with pkgs; [
        ripgrep
        fd
        fzf
        lua-language-server
        nixd
        nixfmt
        marksman
        typescript-language-server
        vscode-langservers-extracted
        yaml-language-server
        tofu-ls
      ];
    };
}
