{ pkgs }:

pkgs.writeShellApplication {
  name = "nixos-activate-fzf";
  runtimeInputs = [
    pkgs.fzf
    pkgs.jq
    pkgs.nix
    pkgs.coreutils
  ];
  text = ''
    # exit on error, unset variables, or failed pipelines
    set -euo pipefail

    # error messages on exit
    fail() {
      local msg="''${1:-unknown error}"
      local code="''${2:-1}"
      printf 'error: %s\n' "$msg" >&2
      exit "$code"
    }

    # require root privileges
    if (( EUID != 0 )); then
      fail "insufficient privileges: run as root (sudo)"
    fi

    profile_dir="/nix/var/nix/profiles"

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
      --height='40%'
      --no-mouse
      --delimiter='[[:space:]]+'
      --nth='1,2,3'
      --accept-nth='1'
    )

    # pick a generation
    selected_generation="$(
      nixos-rebuild list-generations --json \
      | jq -r "$jq_query" \
      | column -s '|' -t \
      | fzf "''${fzf_opts[@]}"
    )"

    active_system="/run/current-system"
    selected_system="''${profile_dir}/system-''${selected_generation}-link"
    switch_cmd="''${selected_system}/bin/switch-to-configuration"

    if [[ ! -e "$switch_cmd" ]]; then
      fail "invalid switch cmd: missing $switch_cmd"
    fi

    # Do nothing if already active
    if [[ "$(readlink -f "$active_system")" == "$(readlink -f "$selected_system")" ]]; then
      exit 0
    fi

    # Execute
    exec "$switch_cmd" switch
  '';
}
