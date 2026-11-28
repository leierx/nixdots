root: {
  flake.modules.homeManager."nixosConfigurations/desktop/home" =
    { pkgs, lib, ... }:
    {
      imports = with root.config.flake.modules.homeManager; [
        homelab
        nix-index
      ];
      # the shell a size up on the 27" 1440p monitors, which run at scale 1
      quickshell.scale = 1.2;
      programs.ssh.settings."*.rsync.net" = {
        IdentityFile = [ "~/.ssh/id_rsync_net" ];
        IdentitiesOnly = true;
      };
      wayland.windowManager.hyprland.settings = {
        # fullscreen games straight to the display, skipping a compositing pass
        config.render.direct_scanout = 2;
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
