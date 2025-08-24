{ pkgs, ... }:
let
  neovimFinalPackage = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
    wrapRc = false;
    wrapperArgs = ''--suffix PATH : "${
      pkgs.lib.makeBinPath (with pkgs; [
        # Dependencies
        git ripgrep fd tree-sitter gcc gnumake
        # language servers + linters
        ansible-language-server # ansiblels
        bash-language-server # bashls
        clang-tools # clangd
        lemminx # XML
        lua-language-server # lua_ls
        marksman # Markdown
        nil alejandra # Nix + Nix formatter
        opentofu-ls # terraform/tofu
        taplo # TOML
        typescript-language-server # tsserver
        vscode-langservers-extracted # html, cssls, jsonls
        yaml-language-server # yamlls
      ])
    }"'';
  };

in {
  home.packages = [ neovimFinalPackage ];

  xdg.configFile."nvim".source = ./.;
  xdg.configFile."nvim".recursive = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };
}
