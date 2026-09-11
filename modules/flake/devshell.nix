# `nix develop` shell: the tools this repository is maintained with.
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.nixfmt
          pkgs.nixd
          pkgs.nix-output-monitor
          (pkgs.writeShellScriptBin "rebuild" ''
            set -euo pipefail
            host="''${1:-$(hostname)}"
            exec sudo nixos-rebuild switch --flake ".#$host"
          '')
          (pkgs.writeShellScriptBin "installer" ''
            set -euo pipefail
            host="''${1:?usage: installer <host>}"
            exec nix build ".#nixosConfigurations.offlineInstaller-$host.config.system.build.isoImage"
          '')
          (pkgs.writeShellScriptBin "update" ''
            set -euo pipefail
            nix flake update
            git add flake.lock
            git commit -m "chore(flake): update flake.lock"
          '')
        ];
      };
    };
}
