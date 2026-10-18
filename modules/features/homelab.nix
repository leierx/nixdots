root: {
  flake.modules.homeManager.homelab =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        just
        kubernetes-helm
        kubevirt
        # `kubectl oidc-login`: the homelab kubeconfig logs in through Authentik
        kubelogin-oidc
      ];

      programs.ssh = {
        enable = true;
        settings.loft01 = {
          HostName = "10.0.0.1";
          User = root.config.identity.username;
          ServerAliveInterval = 30;
          # k3s API, for kubectl and helm
          LocalForward = "6443 127.0.0.1:6443";
        };
      };
    };

  # Hosts that are WireGuard peers of loft01 reach its sites on the wg gateway: Authentik's admin
  # interface only exists there, and Argo CD and Grafana skip the public login gate.
  flake.modules.nixos.homelab = {
    networking.hosts."10.0.0.1" = [
      "auth.skinke.net"
      "argocd.skinke.net"
      "metrics.skinke.net"
    ];
  };
}
