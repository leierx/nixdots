{ config, lib, flakeInputs, pkgs, ... }:
let
  cfg = config.dots.core.user;
in
{
  imports = [ ./zsh.nix ];

  options.dots.core.user = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable user account creation and home-manager setup.";
    };

    name = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "leier";
    };

    shell = lib.mkOption {
      type = lib.types.enum [ "zsh" ];
      default = "zsh";
    };

    secondaryGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = lib.lists.intersectLists ([
        "wheel" "video" "audio" "adm"
        "docker" "podman" "networkmanager"
        "git" "network" "wireshark"
        "libvirtd" "kvm" "mlocate"
      ]) (builtins.attrNames config.users.groups);
    };
  };

  config = lib.mkIf cfg.enable {
    # Disable root user
    users.users.root.hashedPassword = "!";

    # Global default shell
    users.defaultUserShell = lib.mkDefault pkgs.bashInteractive;
    programs.starship.enable = true;

    # Ensure primary group <username> exists
    users.groups.${cfg.name} = {};

    # Create the user account
    users.users.${cfg.name} = {
      isNormalUser = true;
      home = "/home/${cfg.name}";
      homeMode = "0770";
      createHome = true;
      initialHashedPassword = "$6$IwGp276/71CzyoDG$RHOfZSCTLXN2NGk7T8QcYTx815KNhEx42ECUrNxYcdjAga0JD4EVzSgUus.WR2U44Epk8fpcnMdXTIJmYB4dd0";
      group = cfg.name;
      extraGroups = cfg.secondaryGroups;
      description = cfg.name;
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      users.${cfg.name} = {
        home.stateVersion = config.system.stateVersion;
      };
    };
  };
}
