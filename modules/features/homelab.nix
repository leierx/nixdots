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
}
