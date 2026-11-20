export QS_TEST_MONITORS="DP-1:1920x1080:1"

qst case "keys typed as the launcher opens all land, on a shell just started"
qst key super+d
qst type firefox
qst wait '.field == "firefox"'

qst case "the launcher opens within a second of its key"
start=$(date +%s%N)
qst key super+d
qst wait '.panel == "apps" and (.layers | index("DP-1 quickshell:launcher")) != null'
took=$((($(date +%s%N) - start) / 1000000))
[ "$took" -lt 1000 ] || { echo "the launcher took $took ms to open"; exit 1; }
