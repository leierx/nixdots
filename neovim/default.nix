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
        lua-language-server # lua_ls
        nil alejandra # Nix + Nix formatter
        vscode-langservers-extracted # html, cssls, jsonls
        typescript-language-server # tsserver
        bash-language-server # bashls
        clang-tools # clangd
        marksman # Markdown
        taplo # TOML
        lemminx # XML
        yaml-language-server # yamlls
        ansible-language-server # ansiblels
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
