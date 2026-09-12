{
  flake.modules.homeManager."homeConfigurations/desktop" =
    { pkgs, lib, ... }:
    {
      programs.ssh = {
        enable = true;
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
              (lib.generators.mkLuaInline ''function() hl.exec_cmd("${pkgs.discord-canary}/bin/discordcanary") end'')
            ];
          }
          {
            _args = [
              "hyprland.start"
              (lib.generators.mkLuaInline ''function() hl.exec_cmd("${pkgs.firefox-bin}/bin/firefox", {monitor = "DP-1"}) end'')
            ];
          }
        ];
      };
    };
}
