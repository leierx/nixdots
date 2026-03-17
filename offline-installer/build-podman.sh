#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." &>/dev/null && pwd)"

podman run --rm -it \
  -v "$ROOT_DIR:/work" -w /work \
  -e NIX_CONFIG="experimental-features = nix-command flakes" \
  "docker.io/nixos/nix" \
  bash -euo pipefail -c '
    export TARGET_HOST="$(nix flake show --json /work | nix run "nixpkgs#jq" -- -r ".nixosConfigurations | keys[]" | nix run "nixpkgs#fzf")"

    [ -n "${TARGET_HOST:-}" ] || {
      echo "No host selected" >&2
      exit 1
    }

    nix build --impure --no-link --print-out-paths --no-write-lock-file "/work/installer#nixosConfigurations.offlineInstaller.config.system.build.isoImage"
  '
