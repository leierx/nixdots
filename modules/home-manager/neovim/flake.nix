{
  outputs =
    { ... }:
    {
      homeManagerModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.neovimDots;
        in
        {
          options.neovimDots = {
            useOutOfStore = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to use an out-of-store Neovim config";
            };

            outOfStorePath = lib.mkOption {
              type = lib.types.path;
              default = "/home/leier/Projects/nixdots/modules/home-manager/neovim";
              description = "Path to an out-of-store Neovim config";
            };
          };

          config = {
            xdg.configFile."nvim".source =
              if cfg.useOutOfStore then config.lib.file.mkOutOfStoreSymlink cfg.outOfStorePath else ./.;

            home.packages = with pkgs; [
              ripgrep
              fd
              lua-language-server
              nixd
              nixfmt
              ansible-lint
              marksman
              typescript-language-server
              vscode-langservers-extracted
              yaml-language-server
              tofu-ls
            ];
          };
        };
    };
}
