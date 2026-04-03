{ inputs, ... }:
{
  flake.modules.homeManager.hyprland =
    { pkgs, ... }:
    {
      wayland.windowManager.hyprland = {
        plugins = [
          inputs.hyprsplit.packages.${pkgs.stdenv.hostPlatform.system}.hyprsplit
        ];

        settings = {
          plugin.hyprsplit = {
            num_workspaces = 5;
            persistent_workspaces = true;
          };
        };
      };
    };
}
