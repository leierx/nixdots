{
  modules.homeManager.hyprland =
    { pkgs, ... }:
    {
      wayland.windowManager.hyprland = {
        plugins = [
          pkgs.hyprlandPlugins.hyprsplit
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
