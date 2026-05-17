{ inputs, ... }:
{
  modules.homeManager.neovim =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.flakeModules.neovim;
    in
    {
      options.flakeModules.neovim = {
        outOfStorePath = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
        };
      };

      config = {
        xdg.configFile."nvim".source =
          if cfg.outOfStorePath != null then
            config.lib.file.mkOutOfStoreSymlink cfg.outOfStorePath
          else
            "${inputs.assets}/neovim";

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
}
