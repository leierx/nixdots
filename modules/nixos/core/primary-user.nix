{ config, lib, pkgs, flakeInputs, ... }:
{
  options.dots.nixos.core.primaryUser = {
    username = lib.mkOption { type = lib.types.singleLineStr; default = "leier"; };
    setupHomeManager = lib.mkOption { type = lib.types.bool; default = true; };
  };

  config =
    let
      secondaryGroupsHack = lib.lists.intersectLists ([
        "wheel" "video" "audio" "adm"
        "docker" "podman" "networkmanager"
        "git" "network" "wireshark"
        "libvirtd" "kvm" "mlocate"
      ]) (builtins.attrNames config.users.groups);
    in
      {
      # Disable root user
      users.users.root.hashedPassword = "!";

      # Global default shell
      users.defaultUserShell = pkgs.bashInteractive;
      programs.starship.enable = true;

      # Ensure primary group <username> exists
      users.groups."${config.dots.nixos.core.primaryUser.username}" = {};

      # Create the user account
      users.users."${config.dots.nixos.core.primaryUser.username}" = {
        isNormalUser = true;
        home = "/home/${config.dots.nixos.core.primaryUser.username}";
        homeMode = "0770";
        createHome = true;
        initialHashedPassword = "$6$IwGp276/71CzyoDG$RHOfZSCTLXN2NGk7T8QcYTx815KNhEx42ECUrNxYcdjAga0JD4EVzSgUus.WR2U44Epk8fpcnMdXTIJmYB4dd0";
        group = config.dots.nixos.core.primaryUser.username;
        extraGroups = secondaryGroupsHack;
        description = config.dots.nixos.core.primaryUser.username;
      };
    };
}
