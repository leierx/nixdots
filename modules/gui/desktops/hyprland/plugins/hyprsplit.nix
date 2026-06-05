{ inputs, ... }:
{
  modules.homeManager.hyprland =
    { pkgs, ... }:
    {
      wayland.windowManager.hyprland = {
        plugins = [ inputs.hyprsplit.packages.${pkgs.stdenv.hostPlatform.system}.hyprsplit ];
        extraConfig = ''
          local hs = require("hyprsplit")
          hs.config({ num_workspaces = 6 })

          for i = 1, 5 do
            hl.bind("SUPER + " .. i, hs.dsp.focus({ workspace = i }))
            hl.bind("SUPER + SHIFT + " .. i, hs.dsp.window.move({ workspace = i, follow = false }))
          end
        '';
      };
    };
}
