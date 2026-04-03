{
  flake.modules.homeManager.neovim =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      useOutOfStore = false;
      outOfStorePath = null;
    in
    {
      config = {
        xdg.configFile."nvim".source =
          if useOutOfStore then config.lib.file.mkOutOfStoreSymlink outOfStorePath else ./.;

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
