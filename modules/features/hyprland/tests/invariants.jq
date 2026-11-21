# What must hold in every state the shell settles in; qs-test fails a wait or stays on one that lasts, and on a "!" one at once.
# $before: the popups of the snapshot before.
def real: [.screens[].name | select(. != "FALLBACK")];
def wanted:
  if .panel == "" then null
  elif (.panel | startswith("controls:")) then "controls"
  elif (.panel | startswith("tray-overflow:")) then "tray-overflow"
  else { apps: "launcher", clipboard: "launcher", monitors: "launcher", windows: "launcher", nixpkgs: "launcher", center: "center", shortcuts: "shortcuts", power: "power" }[.panel]
  end;

. as $s
| real as $real
| [$s.layers[] | select(contains(" quickshell:")) | split(" quickshell:")[1]] as $shown
| ($s | wanted) as $want
| . + { invariants: [
    (if $want != null and ($real | length) > 0 and ($shown | index($want)) == null then "panel \($s.panel) is open, but no quickshell:\($want) layer is up" else empty end),
    # A menu opened from the tray's overflow sits over it.
    ($shown[] | select(IN("launcher", "center", "shortcuts", "power", "controls", "menu", "tray-overflow")) | select(. != $want and (. != "menu" or $want != "tray-overflow")) | "a quickshell:\(.) layer is up while the open panel is \"\($s.panel)\""),
    ($s.layers[] | select(startswith("FALLBACK quickshell:")) | "\(.) is on Hyprland's FALLBACK, where nobody sees it"),
    (if ($real | length) > 0 then $s.popups[] | select(.screen as $screen | $real | index($screen) | not) | "popup \"\(.summary)\" is on \(.screen), which is not a screen" else empty end),
    # A shell held up this long by anything (a flood, a megabyte of text, a list built over and over) is a frozen desktop.
    (if ($s.answered // 0) > 2000 then "!the shell took \($s.answered) ms to answer the probe" else empty end),
    (if ($s.popups | length) > 5 then "\($s.popups | length) popups are up, past the five allowed" else empty end),
    ($s.history | group_by(.app)[] | .[3:][] | select(.popup | not) | "\(.app) keeps \"\(.summary)\" past its newest three"),
    (if $s.notifications > 105 then "the history holds \($s.notifications), past the 100 kept and five popups" else empty end),
    (if $s.unchecked > $s.notifications then "\($s.unchecked) unchecked of \($s.notifications) notifications" else empty end),
    # A countdown only refills when its popup pops up again, which moves its time.
    ($s.popups[] as $now | $before[0][] | select(.id == $now.id and .shown == $now.shown and $now.remaining != null and $now.remaining > .remaining + 0.02)
      | "!the countdown of \"\($now.summary)\" went back up from \(.remaining * 100 | floor) % to \($now.remaining * 100 | floor) % without popping up again")
  ] }
