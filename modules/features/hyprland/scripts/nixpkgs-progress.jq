# nix's internal-json log in; out, as it changes: download percent, builds done, expected and running, then the download's sizes (last, as it may be empty).
# Activity types: 100 copyPath, 101 fileTransfer, 104 builds; results: 105 progress, 106 setExpected.
def mib: . / 104857.6 | floor | "\(. / 10 | floor).\(. % 10)";
def sizes($got; $total):
  if $total >= 1048576 then "\($got | mib) of \($total | mib) MiB"
  else "\($got / 1024 | floor) of \($total / 1024 | floor) KiB" end;

foreach (inputs | ltrimstr("@nix ") | fromjson? // empty) as $e (
  { types: {}, parents: {}, got: {}, total: 0, builds: [0, 0, 0], shown: null, out: null };
  ($e.id // 0 | tostring) as $id
  | if $e.action == "start" then
      .types[$id] = $e.type | .parents[$id] = ($e.parent // 0 | tostring)
    elif $e.action == "result" and $e.type == 106 and $e.fields[0] == 101 then
      .total = $e.fields[1]
    elif $e.action == "result" and $e.type == 105 and .types[$id] == 101 and .types[.parents[$id]] == 100 then
      .got[$id] = $e.fields[0]
    elif $e.action == "result" and $e.type == 105 and .types[$id] == 104 then
      .builds = $e.fields[0:3]
    else . end
  | ([.got[]] | add // 0) as $got
  | [
      (if .total > 0 then [100, $got * 100 / .total | floor] | min else -1 end),
      .builds[0], .builds[1], .builds[2],
      (if .total > 0 then sizes($got; .total) else "" end)
    ] as $now
  | .out = (if $now == .shown then null else $now end)
  | .shown = $now;
  .out // empty
) | @tsv
