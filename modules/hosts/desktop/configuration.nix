{
  flake.modules.nixos."nixosConfigurations/desktop" =
    { pkgs, ... }:
    {
      networking.firewall.trustedInterfaces = [ "m3lab0" ];

      environment.systemPackages = with pkgs; [
        kubectl-df-pv
        pika-backup
        keymapp
        wireguard-tools
        age
        opentofu
        sops
        signal-desktop
        meld
        gimp
        unstable.openmw

        # Metal3 / Cluster API lab tooling
        act
        butane
        clusterctl
        cosign
        crane
        cryptsetup
        erofs-utils
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
