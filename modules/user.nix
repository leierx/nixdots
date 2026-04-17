{
  flake.factories.nixos.user = username: {
    users.groups.${username} = { };

    users.users.${username} = {
      isNormalUser = true;
      home = "/home/${username}";
      createHome = true;
      homeMode = "0770";
      group = username;

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
  };
}
