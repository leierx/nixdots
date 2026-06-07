{ inputs, ... }:
{
  modules.homeManager.hyprland =
    { pkgs, lib, ... }:
    {
      wayland.windowManager.hyprland = {
        plugins = [ inputs.hyprsplit.packages.${pkgs.stdenv.hostPlatform.system}.hyprsplit ];
        settings.hs._var = lib.generators.mkLuaInline ''
          (function()
            local m = require("hyprsplit")
            m.config({ num_workspaces = 5 })
            return m
          end)()
        '';
      };
    };
}
