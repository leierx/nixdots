{ config, lib, pkgs, ... }:

let
  cfg = config.dots.core.utils;
in
{
  options.dots.core.utils = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "core command-line tooling";
    };

    tools = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "git" "kubectl" "plocate" ]);
      default = [ "git" "kubectl" ];
      description = "Declarative list of small CLI utilities to enable system-wide.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf (lib.elem "git" cfg.tools) {
      programs.git.enable = true;

      home-manager.sharedModules = [
        ({
          programs.git = {
            enable = true;
            extraConfig = {
              url."git@github.com:".insteadOf = "https://github.com/";
              credential.helper = "cache --timeout=36000";
              safe.directory = "*";
            };
            includes = [ ];
            ignores = [ ];
          };
        })
      ];
    })

    (lib.mkIf (lib.elem "kubectl" cfg.tools) {
      environment.systemPackages = with pkgs; [ kubectl kubie kubectl-df-pv ];
    })

    (lib.mkIf (lib.elem "plocate" cfg.tools) {
      services.locate = {
        enable = true;
        package = pkgs.plocate;
        interval = "daily";
        output = "/var/cache/locatedb";
      };
    })
  ]);
}
