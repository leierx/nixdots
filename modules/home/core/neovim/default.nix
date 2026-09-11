top: {
  options.neovim.outOfStorePath = top.lib.mkOption {
    type = top.lib.types.nullOr top.lib.types.path;
    default = null;
    description = "Symlink the neovim config to this path instead of the store, for live editing";
  };

  config.flake.modules.homeManager.neovim =
    { config, pkgs, ... }:
    {
      xdg.configFile."nvim".source =
        if top.config.neovim.outOfStorePath != null then
          config.lib.file.mkOutOfStoreSymlink top.config.neovim.outOfStorePath
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
