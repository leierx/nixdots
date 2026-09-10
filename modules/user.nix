{
  modules.nixos.user = { pkgs, identity, ... }: {
    users.groups.${identity.user} = { };

    users.users.${identity.user} = {
      isNormalUser = true;
      home = "/home/${identity.user}";
      createHome = true;
      homeMode = "0770";
      group = identity.user;
      shell = pkgs.zsh;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
        "incus-admin"
        "podman"
        "input"
      ];

      initialHashedPassword = "$6$IwGp276/71CzyoDG$RHOfZSCTLXN2NGk7T8QcYTx815KNhEx42ECUrNxYcdjAga0JD4EVzSgUus.WR2U44Epk8fpcnMdXTIJmYB4dd0";
    };

    programs.zsh.enable = true; # required for the login shell
    programs.starship.enable = true;
  };
}
