{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.base.nixos;
in
{
  options.nixdots.base.nixos = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable nixdots.base.nixos";
    };
  };

  config = lib.mkIf cfg.enable {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      settings = {
        auto-optimise-store = true;
        flake-registry = lib.mkForce ""; # Disable global registry
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [ "@wheel" ];
      };

      # Thanks to: https://nixos-and-flakes.thiscute.world/best-practices/nix-path-and-flake-registry#custom-nix-path-and-flake-registry
      # make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake
      registry.nixpkgs.flake = inputs.nixpkgs;
      channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead
      nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
    };

    # allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # bloat removal
    documentation.nixos.enable = false;
    networking.dhcpcd.enable = false;
    services.xserver.excludePackages = [ pkgs.xterm ];

    # default editor nano -> neovim
    programs.nano.enable = false;
    programs.neovim = {
      enable = true;
      defaultEditor = true;
    };

    # basic terminal utilities IMO
    environment.systemPackages = [
      pkgs.jq
      pkgs.fzf
      pkgs.fastfetch
      pkgs.tree
    ];

    # clean /tmp on boot
    boot.tmp.cleanOnBoot = true;

    programs.git.enable = true;
    home-manager.users.leier = {
      # git has to be installed in global scope in order for nixos-rebuild to work properly
      programs.git = {
        enable = true;
        settings = {
          credential.helper = "cache --timeout=36000";
          safe.directory = "*";
        };
      };

      # allowUnfree for "nix run" command
      xdg.configFile."nixpkgs/config.nix".text = ''
        {
          allowUnfree = true;
        }
      '';
    };

    # syslog
    services.journald.extraConfig = "MaxRetentionSec=90day";
  };
}
