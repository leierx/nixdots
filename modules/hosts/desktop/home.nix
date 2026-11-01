root: {
  flake.modules.homeManager."nixosConfigurations/desktop/home" =
    { pkgs, lib, ... }:
    {
      imports = [ root.config.flake.modules.homeManager.nix-index ];

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

      programs.quickshell.enable = true;

      # also git's credential helper for github.com over https
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
        matchBlocks = {
          "github.com" = {
            hostname = "github.com";
            user = "git";
            identityFile = [ "~/.ssh/id_ed25519" ];
          };
          "*.rsync.net" = {
            identityFile = [ "~/.ssh/id_rsync_net" ];
            identitiesOnly = true;
          };
        };
      };

      wayland.windowManager.hyprland.settings = {
        window_rule = [
          {
            match.class = "^(discord-canary)$";
            monitor = "DP-2";
          }
        ];
        on = [
          {
            _args = [
              "hyprland.start"
              (lib.generators.mkLuaInline ''function() hl.exec_cmd("${lib.getExe pkgs.discord-canary}") end'')
            ];
          }
          {
            _args = [
              "hyprland.start"
              (lib.generators.mkLuaInline ''function() hl.exec_cmd("${lib.getExe pkgs.firefox-bin}", {monitor = "DP-1"}) end'')
            ];
          }
        ];
      };
    };
}
