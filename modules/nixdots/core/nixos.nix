{
  lib,
  config,
  flakeInputs,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.core.nixos;
in
{
  options.nixdots.core.nixos = {
    enable = lib.mkEnableOption "Enable Nix + system defaults";
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
      registry.nixpkgs.flake = flakeInputs.nixpkgs; # make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
      channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.
      nixPath = [ "nixpkgs=${flakeInputs.nixpkgs.outPath}" ];
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

    # clean /tmp on boot
    boot.tmp.cleanOnBoot = true;

    # git has to be installed in global scope in order for nixos-rebuild to work properly
    programs.git.enable = true;
    home-manager.users.${config.nixdots.core.primaryUser.username} = {
      programs.git = {
        enable = true;

        settings = {
          credential.helper = "cache --timeout=36000";
          safe.directory = "*";
        };
      };
    };

    # syslog
    services.journald.extraConfig = "MaxRetentionSec=90day";
  };
}
