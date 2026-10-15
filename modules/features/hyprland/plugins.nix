root@{ inputs, lib, ... }:
{
  options.hyprland.workspaces = lib.mkOption {
    type = lib.types.ints.positive;
    description = "Number of workspaces on each monitor";
  };

  config.hyprland.workspaces = 6;

  config.flake.modules.homeManager.hyprland =
    { pkgs, ... }:
    {
      wayland.windowManager.hyprland = {
        settings.hs._var = lib.generators.mkLuaInline ''require("hyprsplit")'';
        extraConfig = ''
          hs.config({ num_workspaces = ${toString root.config.hyprland.workspaces}, persistent_workspaces = true })
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
