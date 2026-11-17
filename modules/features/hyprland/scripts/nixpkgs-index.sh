if [ $# -ne 1 ]; then
  echo "usage: nixpkgs-index <file>" >&2
  exit 2
fi
list=$1

# The release the channel points at, so the list and its revision are one release.
release=$(curl -fsSL -o /dev/null -w '%{url_effective}' https://channels.nixos.org/nixos-unstable/git-revision)
release=${release%/git-revision}

# jq holds the whole 400 MB list for a few seconds, so only when the channel moved.
if [ -f "$list" ] && [ "$(head -n 1 "$list" | cut -f 2)" = "$release" ]; then
  exit 0
fi

rev=$(curl -fsSL "$release/git-revision")
tmp=$(mktemp "$list.XXXXXX")
trap 'rm -f "$tmp"' EXIT

# shellcheck disable=SC2016
{
  printf '%s\t%s\n' "$rev" "$release"
  curl -fsSL --compressed "$release/packages.json.br" | nice -n 19 jq -r '
    .packages | to_entries[] | .value as $p
    | select($p.meta.available != false and $p.meta.broken != true)
    | [
        .key,
        ($p.meta.mainProgram // $p.pname // .key),
        ($p.version // ""),
        (if $p.meta.unfree then "unfree" else "" end),
        (($p.meta.description // "") | gsub("[\t\n\r]+"; " "))
      ]
    | @tsv'
} > "$tmp"
mv "$tmp" "$list"
trap - EXIT
echo updated
