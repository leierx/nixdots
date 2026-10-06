{
  flake.modules.nixos."nixosConfigurations/desktop" =
    { pkgs, ... }:
    {
      # wireguard
      networking.firewall.checkReversePath = false;

      environment.systemPackages = with pkgs; [
        kubectl
        kubectl-df-pv
        mousepad
        spotify
        pavucontrol
        brave
        firefox-bin
        pika-backup
        keymapp
        wireguard-tools
        age
        opentofu
        sops
        signal-desktop
        meld
        obsidian
        gimp
        discord-canary
        unstable.openmw

        # Metal3 / Cluster API lab tooling
        act
        butane
        clusterctl
        cosign
        crane
        cryptsetup
        erofs-utils
        gh
        gptfdisk
        just
        kubeconform
        kubernetes-helm
        openssl
        oras
        sbsigntool
        shellcheck
        skopeo
        squashfsTools
        syft
        systemdUkify
        xorriso
        yamllint
        yq-go
      ];
    };
}
