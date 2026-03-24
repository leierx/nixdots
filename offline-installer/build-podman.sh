#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." &>/dev/null && pwd)"

podman run --rm -it \
  -v "$ROOT_DIR:/work" -w /work \
  -e NIX_CONFIG="experimental-features = nix-command flakes" \
  "docker.io/nixos/nix" \
  bash -euo pipefail -c '
    SCRIPT_DIR="/work/offline-installer"
    TARGET_HOST="$(nix shell "nixpkgs#jq" "nixpkgs#fzf" --command bash -c "nix flake show --json $SCRIPT_DIR/.. | jq -r \".nixosConfigurations | keys[]\" | fzf")"

    [ -n "${TARGET_HOST:-}" ] || {
      echo "No host selected" >&2
      exit 1
    }

    ISO_BUILD_PATH="$(nix build --impure --no-link --print-out-paths --no-write-lock-file "${SCRIPT_DIR}#nixosConfigurations.offlineInstaller-${TARGET_HOST}.config.system.build.isoImage")"

    cp "$ISO_BUILD_PATH/iso/"*.iso "$SCRIPT_DIR/"
  '
