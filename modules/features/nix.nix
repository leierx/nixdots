{
  flake.modules.nixos.nix = {
    # the `nixpkgs` registry entry and NIX_PATH come from nixpkgs.flake.source (lib.nixosSystem)
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      # hard-links the store daily rather than on every write (auto-optimise-store)
      optimise.automatic = true;

      # builds yield to the desktop
      daemonCPUSchedPolicy = "batch";
      daemonIOSchedClass = "idle";

      settings = {
        flake-registry = "";
        warn-dirty = false;
        # the 1 MiB default stalls on large substitutions
        download-buffer-size = 256 * 1024 * 1024;
        # a GC starts as free space drops under 10 GiB, until 50 GiB are free
        min-free = 10 * 1024 * 1024 * 1024;
        max-free = 50 * 1024 * 1024 * 1024;
        # wheel is root already through doas
        trusted-users = [ "@wheel" ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        substituters = [ "https://nix-community.cachix.org" ];
        trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
      };

      channel.enable = false;
    };
  };
}
