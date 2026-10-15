{
  flake.modules.nixos.neovim = {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
    };
    programs.nano.enable = false;
  };

  flake.modules.homeManager.neovim =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.neovim.outOfStorePath = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/home/me/nixdots/modules/features/neovim";
        description = ''
          Symlink ~/.config/nvim to this checkout of the neovim feature instead of
          the store, for live editing; vim.pack then updates the committed lockfile.
        '';
      };

      config = {
        programs.neovim = {
          enable = true;
          viAlias = true;
          vimAlias = true;
          defaultEditor = true;
          # on nvim's PATH only, so they don't shadow project dev shells
          extraPackages = with pkgs; [
            # nvim-treesitter (main) compiles parsers with these
            tree-sitter
            gcc
            # LSP servers (defaults from nvim-lspconfig, overrides in after/lsp/)
            lua-language-server
            nixd
            marksman
            typescript-language-server
            vscode-langservers-extracted
            yaml-language-server
            tofu-ls
            qt6.qtdeclarative # QML: qmlls, qmlformat, qmllint (quickshell configs)
            gopls
            fzf # fzf-lua
            # conform formatters
            nixfmt
            gotools # goimports
            gofumpt
          ];
        };

        xdg.configFile."nvim".source =
          if config.neovim.outOfStorePath != null then
            config.lib.file.mkOutOfStoreSymlink config.neovim.outOfStorePath
          else
            ./.;

        # fzf-lua's finders, shared with the shell
        programs.ripgrep.enable = true;
        programs.fd.enable = true;
      };
    };
}
