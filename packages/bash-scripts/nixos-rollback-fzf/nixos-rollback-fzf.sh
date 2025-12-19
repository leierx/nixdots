#!/usr/bin/env bash
set -euo pipefail

# error messages on exit
fail() {
  local msg="${1:-unknown error}"
  local code="${2:-1}"
  printf 'error: %s\n' "$msg" >&2
  exit "$code"
}

# sanity checks
command -v nixos-rebuild &>/dev/null || fail "nixos-rebuild is not available; this script must be run on NixOS"
[[ $EUID -ne 0 ]] && fail "insufficient privileges: run as root (sudo)"

jq_query='
  (["generation","nixosVersion","kernelVersion","date"] | join(" | ")),
  (
    .[]
    | [.generation, .nixosVersion, .kernelVersion, .date]
    | select(all(.[]; . != null and . != ""))
    | join(" | ")
  )
'
fzf_opts=(
  --header-lines='1'
  --prompt='nixos generation > '
  --reverse
  --no-mouse
  --delimiter='[[:space:]]+'
  --nth='1,2,3'
  --accept-nth='1'
)

selected_generation="$(nixos-rebuild list-generations --json | jq -r "$jq_query" | column -s '|' -t | fzf "${fzf_opts[@]}")"
profile_dir="/nix/var/nix/profiles"
active_system="/run/current-system"
selected_system="${profile_dir}/system-${selected_generation}-link"
switch_cmd="${selected_system}/bin/switch-to-configuration"

# sanity checks
[[ ! -e "$switch_cmd" ]] && fail "invalid switch cmd: missing $switch_cmd"
[[ "$(readlink -f "$active_system")" == "$(readlink -f "$selected_system")" ]] && exit 0

# Execute
exec "$switch_cmd" switch
