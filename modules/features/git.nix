root: {
  flake.modules.nixos.git.programs.git.enable = true;

  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      settings = {
        user.name = root.config.identity.fullName;
        user.email = root.config.identity.email;
        credential.helper = "cache --timeout=36000";
        safe.directory = "*";
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        merge.conflictStyle = "zdiff3";
        diff.algorithm = "histogram";
        fetch.prune = true;
      };
    };
  };
}
