#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
export TARGET_HOST="$(nix shell 'nixpkgs#jq' 'nixpkgs#fzf' --command bash -c "nix flake show --json $SCRIPT_DIR/.. | jq -r '.nixosConfigurations | keys[]' | fzf" )"

[ -n "${TARGET_HOST:-}" ] || {
  echo "No host selected" >&2
  exit 1
}

nix build --impure --no-link --print-out-paths --no-write-lock-file "$SCRIPT_DIR#nixosConfigurations.offlineInstaller.config.system.build.isoImage"

