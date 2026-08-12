#!/usr/bin/env bash
#
# Drives config/hypr/waybar-autohide.sh against a stubbed Hyprland and checks
# that the bar shows, hides and pins when it should — plus that the idle poll
# rate stays in budget.
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'kill "${WATCHER_PID:-0}" 2>/dev/null; rm -rf "$WORK"' EXIT

BIN="$WORK/bin"
mkdir -p "$BIN" "$WORK/config/waybar"

CURSOR="$WORK/cursor"      # pointer y, rewritten by the test
SIGNALS="$WORK/signals"    # every signal the script sends
CALLS="$WORK/calls"        # every stubbed command it runs
echo 500 >"$CURSOR"
: >"$SIGNALS"
: >"$CALLS"

cat >"$BIN/hyprctl" <<EOF
#!/usr/bin/env bash
echo hyprctl >>"$CALLS"
echo "1920, \$(cat "$CURSOR")"
EOF

cat >"$BIN/pkill" <<EOF
#!/usr/bin/env bash
echo pkill >>"$CALLS"
echo "\$1" >>"$SIGNALS"
exit 0
EOF

cat >"$BIN/pgrep" <<EOF
#!/usr/bin/env bash
echo pgrep >>"$CALLS"
exit 0
EOF

chmod +x "$BIN"/*

export PATH="$BIN:$PATH"
export XDG_CONFIG_HOME="$WORK/config"
export XDG_RUNTIME_DIR="$WORK"

fail=0

expect_signal() {
    local signal="$1" what="$2" deadline=$((SECONDS + 3))
    while (( SECONDS < deadline )); do
        grep -q -- "$signal" "$SIGNALS" && { echo "  ok   $what"; return 0; }
        sleep 0.1
    done
    echo "  FAIL $what (never saw $signal)"
    fail=1
}

expect_no_signal() {
    local signal="$1" what="$2"
    sleep 0.6
    if grep -q -- "$signal" "$SIGNALS"; then
        echo "  FAIL $what (unexpected $signal)"
        fail=1
    else
        echo "  ok   $what"
    fi
}

echo 0 >"$WORK/config/waybar/.pinned"
bash "$ROOT/config/hypr/waybar-autohide.sh" &
WATCHER_PID=$!
sleep 2.2   # the watcher settles for 1.5s before its first poll

# 1. Pointer in the middle of the screen: bar stays hidden.
expect_no_signal SIGUSR1 "stays hidden while the pointer is away"

# 2. Pointer at the very top: bar appears.
echo 4 >"$CURSOR"
expect_signal SIGUSR1 "shows when the pointer reaches the top edge"

# 3. Pointer moves back down: bar hides again.
: >"$SIGNALS"
echo 400 >"$CURSOR"
expect_signal SIGUSR2 "hides again when the pointer leaves"

# 4. Pinning shows the bar wherever the pointer is.
: >"$SIGNALS"
echo 1 >"$WORK/config/waybar/.pinned"
expect_signal SIGUSR1 "shows and stays when pinned"

# 5. While pinned and far away, it must not hide.
: >"$SIGNALS"
expect_no_signal SIGUSR2 "does not hide while pinned"

# 6. Poll budget with the pointer parked far from the bar.
echo 0 >"$WORK/config/waybar/.pinned"
sleep 0.5
: >"$CALLS"
sleep 4
calls=$(wc -l <"$CALLS")
rate=$(( calls / 4 ))
if (( rate <= 8 )); then
    echo "  ok   idle poll rate ${rate}/s (${calls} processes in 4s, budget 8/s)"
else
    echo "  FAIL idle poll rate ${rate}/s exceeds the 8/s budget"
    fail=1
fi

kill "$WATCHER_PID" 2>/dev/null
wait "$WATCHER_PID" 2>/dev/null

exit $fail
