{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    extraPackages = with pkgs; [
      # Dependencies
      git ripgrep fd tree-sitter gcc gnumake
      # language servers + linters
      bash-language-server # bashls
      clang-tools # clangd
      lemminx # XML
      lua-language-server # lua_ls
      marksman # Markdown
      nil alejandra # Nix + formatter
      tofu-ls # terraform/tofu
      taplo # TOML
      typescript-language-server
      vscode-langservers-extracted # html, cssls, jsonls
      yaml-language-server # yamlls
    ];
  };

  xdg.configFile."nvim".source = ./.;
  xdg.configFile."nvim".recursive = true;
}
