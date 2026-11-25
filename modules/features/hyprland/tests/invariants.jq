# What must hold in every state the shell settles in; qs-test fails a wait or stays on one that lasts, and on a "!" one at once.
# $before: the popups of the snapshot before.
def real: [.screens[].name | select(. != "FALLBACK")];
def wanted:
  if .panel == "" then null
  elif (.panel | startswith("controls:")) then "controls"
  elif (.panel | startswith("center:")) then "center"
  elif (.panel | startswith("tray-menu:")) then "menu"
  else { apps: "launcher", clipboard: "launcher", monitors: "launcher", windows: "launcher", nixpkgs: "launcher", shortcuts: "shortcuts", power: "power", gallery: "gallery" }[.panel]
  end;
# The screen a per-screen panel is on, or null.
def panelScreen: if (.panel | test("^(controls|center|tray-menu):")) then .panel | sub("^[^:]*:"; "") else null end;

. as $s
| real as $real
| [$s.layers[] | select(contains(" quickshell:")) | split(" quickshell:")[1]] as $shown
| ($s | wanted) as $want
| ($s | panelScreen) as $on
| . + { invariants: [
    (if $s.panel != "" and $want == null then "the open panel \"\($s.panel)\" is no panel the shell has" else empty end),
    (if $on != null and ($real | index($on)) == null then "the open panel \($s.panel) is for a screen that is not there" else empty end),
    # The shortcuts come up once Hyprland's binds are read, which a slow hyprctl holds up to 5 s.
    (if $want != null and $want != "shortcuts" and ($real | length) > 0 and ($shown | index($want)) == null then "panel \($s.panel) is open, but no quickshell:\($want) layer is up" else empty end),
    (if $on != null and ($real | index($on)) != null and ($s.layers | index("\($on) quickshell:\($want)")) == null then "panel \($s.panel) is open, but not on \($on)" else empty end),
    ($shown[] | select(IN("launcher", "center", "shortcuts", "power", "controls", "menu", "gallery")) | select(. != $want) | "a quickshell:\(.) layer is up while the open panel is \"\($s.panel)\""),
    ($shown | group_by(.)[] | select(length > 1 and IN(.[0]; "launcher", "center", "shortcuts", "power", "controls", "menu", "gallery")) | "\(length) quickshell:\(.[0]) layers are up at once"),
    ($s.layers[] | select(startswith("FALLBACK quickshell:")) | "\(.) is on Hyprland's FALLBACK, where nobody sees it"),
    # Every screen has its bar, the layer that takes a click on bare desktop, and the one its popups go in; one each.
    ($real[] as $screen | ("bar", "click-away", "notifications") as $kind | [$s.layers[] | select(. == "\($screen) quickshell:\($kind)")] | length | select(. != 1) | "\($screen) has \(.) quickshell:\($kind) layers, not one"),
    # The dim covers every screen or none.
    ([$s.layers[] | select(endswith(" quickshell:idle"))] | length | select(. != 0 and . != ($real | length)) | "the idle dim is on \(.) of \($real | length) screens"),
    (if ($s.tooltip != null) != ($s.layers | any(endswith(" quickshell:tooltip"))) then "a tooltip is \(if $s.tooltip == null then "drawn with none to show" else "shown with no layer to draw it" end)" else empty end),
    # The shell's screens are Hyprland's monitors that are on, by name and id.
    (([$s.screens[] | select(.name != "FALLBACK") | { name, id: .monitor }] | sort) as $mine
      | ([$s.hypr[] | select((.disabled | not) and .name != "FALLBACK") | { name, id }] | sort) as $theirs
      | if $mine != $theirs then "the shell's screens \($mine | map("\(.name)=\(.id)") | join(", ")) are not Hyprland's \($theirs | map("\(.name)=\(.id)") | join(", "))" else empty end),
    (if ($real | length) > 0 then $s.popups[] | select(.screen as $screen | $real | index($screen) | not) | "popup \"\(.summary)\" is on \(.screen), which is not a screen" else empty end),
    # A shell held up this long by anything (a flood, a megabyte of text, a list built over and over) is a frozen desktop.
    (if ($s.answered // 0) > 2000 then "!the shell took \($s.answered) ms to answer the probe" else empty end),
    (if ($s.popups | length) > 5 then "\($s.popups | length) popups are up, past the five allowed" else empty end),
    ($s.history | group_by(.app)[] | .[3:][] | select(.popup | not) | "\(.app) keeps \"\(.summary)\" past its newest three"),
    (if $s.notifications > 105 then "the history holds \($s.notifications), past the 100 kept and five popups" else empty end),
    (if $s.unchecked > $s.notifications then "\($s.unchecked) unchecked of \($s.notifications) notifications" else empty end),
    # What the status button shows is what its backends say.
    ($s.status[] | .glyphs as $glyphs | .screen as $screen | (
      (if ($glyphs | index("caffeine") != null) != $s.caffeine then "\($screen)'s status button \(if $s.caffeine then "has no" else "shows a" end) cup with Caffeine \(if $s.caffeine then "on" else "off" end)" else empty end),
      (if ($glyphs | index("bell") != null) != ($s.unchecked > 0 and ($s.dnd | not)) then "\($screen)'s status button \(if ($glyphs | index("bell")) != null then "rings" else "has no" end) bell with \($s.unchecked) unchecked\(if $s.dnd then " under Do Not Disturb" else "" end)" else empty end),
      (if ($glyphs | index("dnd") != null) != $s.dnd then "\($screen)'s status button disagrees with Do Not Disturb" else empty end),
      (if ($glyphs | index("Microphone") != null) != ($s.privacy.mic | length > 0) then "\($screen)'s status button disagrees with what records the microphone" else empty end)
    )),
    # A clock shows pressed exactly while its own center is open.
    (($s.clocks | sort) as $clocks | (if ($s.panel | startswith("center:")) then [$on] else [] end) as $center | if $clocks != $center then "the clocks pressed are \($clocks), the open center's \($center)" else empty end),
    ($s.sliders[] | select(.value == null) | "slider \(.name) has no value"),
    # A countdown only refills when its popup pops up again, which moves its time.
    ($s.popups[] as $now | $before[0][] | select(.id == $now.id and .shown == $now.shown and $now.remaining != null and $now.remaining > .remaining + 0.02)
      | "!the countdown of \"\($now.summary)\" went back up from \(.remaining * 100 | floor) % to \($now.remaining * 100 | floor) % without popping up again")
  ] }
