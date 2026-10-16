root: {
  flake.modules.homeManager.homelab =
    { config, pkgs, ... }:
    {
      home.sessionVariables.KUBECONFIG = "${config.home.homeDirectory}/.kube/loft01";

      home.packages = with pkgs; [
        just
        kubernetes-helm
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
