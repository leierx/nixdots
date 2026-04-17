{
  flake.factories.homeManager.neovim =
    {
      useOutOfStore ? false,
      outOfStorePath ? null,
    }:
    {
      config,
      pkgs,
      ...
    }:
    {
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
}
