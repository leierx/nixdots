{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    defaultEditor = false;
    languages = {};
    extraPackages = with pkgs; [
      # language servers
      bash-language-server # bashls
      clang-tools # clangd
      gopls # go ls
      lemminx # XML
      lua-language-server # lua_ls
      marksman # Markdown
      nil # nix ls
      tofu-ls # terraform/tofu
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
        auto-info = true;
        bufferline = "multiple"; # sounds cool
        line-number = "relative"; # enables relative J,K jumping
        color-modes = true;
        popup-border = "all"; # default = none

        gutters = [ "diff" "diagnostics" "line-numbers" "spacer" ];

        cursor-shape = {
          insert = "bar";
          select = "underline";
        };

        whitespace.render = {
          space = "all";
          tab = "all";
          nbsp = "all";
          nnbsp = "all";
        };

        indent-guides.render = true;

        soft-wrap.enable = true;

        statusline = {
          left = ["mode" "file-name" "read-only-indicator" "file-modification-indicator"];
          center = [];
          right = ["version-control" "spinner" "diagnostics" "file-type" "position"];
          mode = {
            normal = "NORMAL";
            insert = "INSERT";
            select = "SELECT";
          };
        };
      };

      keys = (import ./keymaps.nix);
    };
  };
}
