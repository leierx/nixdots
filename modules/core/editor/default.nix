{ config, lib, pkgs, flakeInputs, ... }:
let
  cfg = config.dots.core.editor;
in
{
  options.dots.core.editor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "configuration of the system default terminal editor (e.g. sets $EDITOR)";
    };

    program = lib.mkOption {
      type = lib.types.enum [ "nvim" ];
      default = "nvim";
      description = "Editor program to configure";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf (cfg.program == "nvim") {
      home-manager.sharedModules = [
        (import "${flakeInputs.self.outPath}/neovim" { inherit pkgs; })
      ];
    })
  ]);
}
