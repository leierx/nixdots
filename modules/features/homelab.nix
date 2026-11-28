root: {
  flake.modules.homeManager.homelab =
    { pkgs, ... }:
    {
      imports = [ root.config.flake.modules.homeManager.ssh ];

      home.packages = with pkgs; [
        just
        kubectl
        kubernetes-helm
        kubevirt
        # `kubectl oidc-login`: the homelab kubeconfig logs in through Authentik
        kubelogin-oidc
      ];
      # also git's credential helper for github.com over https
      programs.gh = {
        enable = true;
        settings.aliases.co = "pr checkout";
      };
      programs.ssh.settings.loft01 = {
        HostName = "10.0.0.1";
        User = root.config.identity.username;
        ServerAliveInterval = 30;
        # k3s API, for kubectl and helm
        LocalForward = "6443 127.0.0.1:6443";
      };
    };
}
