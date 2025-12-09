{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    defaultEditor = false;
    languages = {};
    extraPackages = with pkgs; [
      # language servers
      ansible-language-server # ansiblels
      bash-language-server # bashls
      clang-tools # clangd
      gopls # go ls
      lemminx # XML
      lua-language-server # lua_ls
      marksman # Markdown
      nil # nix ls
      opentofu-ls # terraform/tofu
      pyright # python ls
      rust-analyzer # rust ls
      taplo # TOML
      typescript-language-server # typescript ls
      vscode-langservers-extracted # html, cssls, jsonls
      yaml-language-server # yamlls
    ];
    settings = {
      # theme
      theme = "kanagawa";

      editor = {
        mouse = false; # disable mouse input
        middle-click-paste = false; # I dont use it
        default-yank-register = "+"; # primary
        cursorline = true;
        auto-format = false;
        trim-trailing-whitespace = true;

        auto-info = true; # default, may remove later

        bufferline = "multiple"; # sounds cool
        line-number = "relative"; # enables relative J,K jumping
        color-modes = true;
        popup-border = "all"; # default = none

        gutters = [ "diff" "diagnostics" "line-numbers" "spacer" ];

        cursor-shape.insert = "bar"; # block for everything else
        whitespace.render = { space = "all"; tab = "all"; nbsp = "all"; nnbsp = "all"; };
        indent-guides.render = true;

        # soft-wrap = { }; # might configure later

        statusline = {
          left = ["mode" "spacer" "version-control" "file-name" "read-only-indicator" "file-modification-indicator"];
          center = [];
          right = ["spinner" "diagnostics" "file-type" "position"];
          mode.normal = "NORMAL";
          mode.insert = "INSERT";
          mode.select = "SELECT";
        };
      };
    };
  };
}
