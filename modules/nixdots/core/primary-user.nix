{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.core.primaryUser;

  # only include groups that actually exist (so this module stays reusable)
  secondaryGroups = lib.lists.intersectLists [
    "wheel"
    "video"
    "audio"
    "adm"
    "docker"
    "podman"
    "networkmanager"
    "git"
    "network"
    "wireshark"
    "libvirtd"
    "kvm"
    "mlocate"
  ] (builtins.attrNames config.users.groups);
in
{
  options.nixdots.core.primaryUser = {
    enable = lib.mkEnableOption "Enable primary user";

    username = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "leier";
      description = "Primary login user.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Disable root user login (password auth)
    users.users.root.hashedPassword = "!";

    # default shell: bash, personal user: zsh
    users.defaultUserShell = pkgs.bashInteractive;
    programs.zsh.enable = true;

    # prompt
    programs.starship.enable = true;

    # Ensure primary group <username> exists
    users.groups.${cfg.username} = { };

    # Create the user account
    users.users.${cfg.username} = {
      isNormalUser = true;
      home = "/home/${cfg.username}";
      createHome = true;
      homeMode = "0770";
      shell = pkgs.zsh;
      group = cfg.username;
      extraGroups = secondaryGroups;
      description = cfg.username;
      initialHashedPassword = "$6$IwGp276/71CzyoDG$RHOfZSCTLXN2NGk7T8QcYTx815KNhEx42ECUrNxYcdjAga0JD4EVzSgUus.WR2U44Epk8fpcnMdXTIJmYB4dd0";
    };

    # home-manager
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      users.${cfg.username} = {
        home.stateVersion = config.system.stateVersion;
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
    };
  };
}
