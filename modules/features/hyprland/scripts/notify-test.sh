# Every kind of notification the quickshell daemon handles.
# notify-test            run them all, a moment apart (GAP=seconds)
# notify-test list       name them
# notify-test NAME...    run some
gap=${GAP:-1.5}

# Actions make notify-send wait, so these run in the background and report what was picked.
waits() { (picked=$(notify-send "$@") || true; echo "  [$2] action: ${picked:-none (dismissed or expired)}") & }

basic()        { notify-send "Summary only"; }
body()         { notify-send -a Test "Summary and body" "A plain one-line body."; }
low()          { notify-send -u low -a Test "Low urgency" "Silent, no sound."; }
critical()     { notify-send -u critical -a Test "Critical" "Red border, its own sound, never times out, pops up over fullscreen and through Do Not Disturb."; }
icon_name()    { notify-send -a Firefox -n firefox "App icon by name" "Papirus' firefox icon."; }
icon_lookup()  { notify-send -a Discord "App icon from the desktop entry" "No icon sent; found through the Discord desktop entry."; }
icon_file()    { notify-send -a Test -n "$photo" "App icon from a file" "A JPEG path as the app icon."; }
no_icon()      { notify-send -a "Zeta Unknown" "No icon at all" "The center falls back to the app's first letter."; }
image()        { notify-send -a Screenshot -n camera-photo -h "string:image-path:$wide" "Image" "A wide picture, cropped square beside the text."; }
image_tall()   { notify-send -a Gallery -h "string:image-path:$photo" "Another image" "From a JPEG file."; }
markup()       { notify-send -a Markup "Body markup" '<b>bold</b>, <i>italic</i>, <u>underline</u> and a <a href="https://www.yr.no">link to yr.no</a>.'; }
escapes()      { notify-send -a Escapes 'Entities & <brackets>' 'Tom &amp; Jerry: 1 &lt; 2, and a bare & ampersand.'; }
chromium()     { notify-send -a "Google Chrome" -h string:desktop-entry:google-chrome "Chromium-style origin" '<a href="https://github.com/">github.com</a>
The site link Chromium puts first is dropped.'; }
long()         { notify-send -a Mail "A long body" "$(printf 'This sentence repeats to fill several lines so the popup cuts it at four lines and a click expands it. %.0s' 1 2 3 4 5 6)"; }
blank_lines()  { notify-send -a Notes "Blank lines" "$(printf 'First paragraph.\n\n\n\n\nSecond paragraph, after five newlines that collapse to one blank line.\n\n\n')"; }
unicode()      { notify-send -a Unicode "Ünïcödé ✓ 🎉 日本語" "Emoji 🚀, accents æøå ÆØÅ, and right-to-left: مرحبا"; }
actions()      { waits -a Calendar -A default=Open -A snooze=Snooze -A dismiss=Dismiss "Actions" "In the center a click expands it, then runs the default action."; }
many_actions() { waits -a Updater -A one=One -A two=Two -A three=Three -A four=Four -A five=Five "Five actions" "Past three, the rest fold into More."; }
one_action()   { waits -a Download -A open=Open "One action, no default" "A click on the card dismisses it."; }
progress()     { local id v; id=$(notify-send -p -a Downloads -h int:value:0 "Downloading" "0%"); for v in 20 40 60 80 100; do sleep 0.6; notify-send -r "$id" -a Downloads -h int:value:$v "Downloading" "$v%"; done; }
replace_id()   { local id; id=$(notify-send -p -a Build "Build started" "Compiling…"); sleep 2; notify-send -r "$id" -a Build "Build finished" "Updated in place: same card, timeout restarted."; }
synchronous()  { local v; for v in 10 30 50 70 90; do notify-send -a Volume -h string:x-canonical-private-synchronous:volume -h int:value:$v -n audio-volume-high "Volume" "$v%"; sleep 0.3; done; }
transient()    { notify-send -e -a Test "Transient" "Never reaches the history once its popup goes."; }
short()        { notify-send -t 2000 -a Test "2 second timeout" "The app's own timeout."; }
sticky()       { notify-send -t 0 -a Test "Timeout 0" "Stays until dismissed."; }
quiet()        { notify-send -a Test -h boolean:suppress-sound:true "suppress-sound" "Normal urgency, but silent."; }
sound_file()   { notify-send -a Test -h "string:sound-file:$bell" "sound-file" "The app's own sound: freedesktop's bell."; }
group()        { local i; for i in 1 2 3 4; do notify-send -a Slack -n slack "Message $i" "Four from one app: one card in the center, two shown, the second dimmed."; sleep 0.2; done; }
burst()        { local i; for i in 1 2 3 4 5 6 7; do notify-send -a Burst "Burst $i of 7" "Only the newest five pop up."; done; }
dnd()          { qs ipc -c shell call notifications setDnd true; notify-send -a Test "Hidden by Do Not Disturb" "Only in the center."; notify-send -u critical -a Test "Critical through Do Not Disturb" "Still pops up."; sleep 3; qs ipc -c shell call notifications setDnd false; }

tests=(basic body low critical icon_name icon_lookup icon_file no_icon image image_tall markup escapes chromium long blank_lines unicode actions many_actions one_action progress replace_id synchronous transient short sticky quiet sound_file group burst dnd)

case ${1:-all} in
  list) printf '%s\n' "${tests[@]}" ;;
  all) for t in "${tests[@]}"; do echo "$t"; "$t"; sleep "$gap"; done; wait ;;
  *) for t in "$@"; do echo "$t"; "$t"; done; wait ;;
esac
