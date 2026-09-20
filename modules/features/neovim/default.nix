root: {
  options.neovim.outOfStorePath = root.lib.mkOption {
    type = root.lib.types.nullOr root.lib.types.path;
    default = null;
    description = "Symlink the neovim config to this path instead of the store, for live editing";
  };

  config.flake.modules.nixos.neovim = {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
    };
    programs.nano.enable = false;
  };

  config.flake.modules.homeManager.neovim =
    { config, pkgs, ... }:
    {
      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
      };

      xdg.configFile."nvim".source =
        if root.config.neovim.outOfStorePath != null then
          config.lib.file.mkOutOfStoreSymlink root.config.neovim.outOfStorePath
        else
          ./.;

      home.packages = with pkgs; [
        ripgrep
        fd
        fzf
        # nvim-treesitter (main) compiles parsers with these
        tree-sitter
        gcc
        # LSP servers (defaults from nvim-lspconfig, overrides in lsp/)
        lua-language-server
        nixd
        nixfmt
        marksman
        typescript-language-server
        vscode-langservers-extracted
        yaml-language-server
        tofu-ls
        qt6.qtdeclarative # QML: qmlls, qmlformat, qmllint (quickshell configs)
        # Go (only what nvim drives: gopls, conform formatters)
        gopls
        gotools # goimports
        gofumpt
      ];
    };
}
