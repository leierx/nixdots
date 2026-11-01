root: {
  flake.modules.homeManager."nixosConfigurations/thonkpad/home" =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        just
        kubernetes-helm
        kubevirt
        # `kubectl oidc-login`: the homelab kubeconfig logs in through Authentik
        kubelogin-oidc
      ];

      piAgent.settings = {
        defaultProvider = "opencode-go";
        defaultModel = "deepseek-v4.1-flash";
        defaultThinkingLevel = "high";
      };

      programs.gh = {
        enable = true;
        settings.aliases.co = "pr checkout";
      };

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
