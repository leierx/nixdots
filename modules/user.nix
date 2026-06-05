{
  modules.nixos.user =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.flakeModules.user;
    in
    {
      options.flakeModules.user = {
        name = lib.mkOption {
          type = lib.types.singleLineStr;
          default = "leier";
          description = "Primary user account name (Unix username)";
        };
      };

      config = {
        users.groups.${cfg.name} = { };

        users.users.${cfg.name} = {
          isNormalUser = true;
          home = "/home/${cfg.name}";
          createHome = true;
          homeMode = "0770";
          group = cfg.name;
          shell = pkgs.zsh;
          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "audio"
            "lp"
            "scanner"
            "libvirtd"
            "kvm"
            "incus-admin"
            "podman"
            "wireshark"
            "input"
          ];

          initialHashedPassword = "$6$IwGp276/71CzyoDG$RHOfZSCTLXN2NGk7T8QcYTx815KNhEx42ECUrNxYcdjAga0JD4EVzSgUus.WR2U44Epk8fpcnMdXTIJmYB4dd0";
        };

        programs.zsh.enable = true;
        programs.starship.enable = true;
      };
    };

  modules.homeManager.user = {
    programs.zsh = {
      enable = true;

      oh-my-zsh.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;

      history = {
        size = 10000;
        save = 690000;
      };

      autosuggestion = {
        enable = true;
        highlight = "fg=246";
      };

      initContent = ''
        # Accept autosuggestion with Ctrl+Space
        bindkey '^ ' autosuggest-execute
      '';
    };
  };
}
