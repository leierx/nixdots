{ inputs, ... }:
{
  modules.homeManager.hyprland =
    { pkgs, ... }:
    {
      wayland.windowManager.hyprland = {
        extraConfig = ''
          local hs = require("hyprsplit")
          hs.config({ num_workspaces = 5, persistent_workspaces = true })
        '';
      };
      xdg.configFile = {
        "hypr/hyprsplit" = {
          source = "${
            inputs.hyprsplit.packages.${pkgs.stdenv.hostPlatform.system}.hyprsplitlua
          }/share/hyprsplit";
          recursive = true;
        };
      };
    };
}
