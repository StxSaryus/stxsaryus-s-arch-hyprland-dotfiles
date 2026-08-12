#!/usr/bin/env bash
#
# Counts the processes the auto-hide watcher spawns while the pointer sits
# in the middle of the screen — the state a laptop is in almost all day.
#
#   ./tests/bench-autohide.sh [seconds] [git-ref-for-the-old-version]
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DURATION="${1:-10}"
BASE_REF="${2:-origin/main}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

git -C "$ROOT" show "$BASE_REF:config/hypr/waybar-autohide.sh" >"$WORK/old.sh" 2>/dev/null || {
    echo "cannot read the previous version from $BASE_REF" >&2
    exit 1
}
cp "$ROOT/config/hypr/waybar-autohide.sh" "$WORK/new.sh"

measure() {
    local script="$1" label="$2"
    local dir="$WORK/$label"
    local bin="$dir/bin"
    mkdir -p "$bin" "$dir/config/waybar"
    echo 0 >"$dir/config/waybar/.pinned"
    echo 600 >"$dir/cursor"
    : >"$dir/calls"

    # Every external command the two versions use, wrapped so we can count it.
    local cmd
    for cmd in awk tr cat sed grep pgrep sleep; do
        cat >"$bin/$cmd" <<EOF
#!/usr/bin/env bash
echo $cmd >>"$dir/calls"
exec /usr/bin/$cmd "\$@"
EOF
    done
    cat >"$bin/hyprctl" <<EOF
#!/usr/bin/env bash
echo hyprctl >>"$dir/calls"
echo "1920, \$(/usr/bin/cat "$dir/cursor")"
EOF
    for cmd in pkill killall; do
        cat >"$bin/$cmd" <<EOF
#!/usr/bin/env bash
echo $cmd >>"$dir/calls"
exit 0
EOF
    done
    # The old version bails out if pidof finds another copy of itself.
    cat >"$bin/pidof" <<EOF
#!/usr/bin/env bash
echo pidof >>"$dir/calls"
exit 1
EOF
    chmod +x "$bin"/*

    (
        export PATH="$bin:/usr/bin:/bin"
        export XDG_CONFIG_HOME="$dir/config"
        export XDG_RUNTIME_DIR="$dir"
        bash "$script" &
        watcher=$!
        sleep 2.5                       # let the startup delay pass
        : >"$dir/calls"
        sleep "$DURATION"
        kill "$watcher" 2>/dev/null
        pkill -P "$watcher" 2>/dev/null
        wait "$watcher" 2>/dev/null
    ) >/dev/null 2>&1

    wc -l <"$dir/calls" | tr -d ' '
}

printf 'Idle for %ss, pointer parked at y=600 (bar hidden, not pinned)\n\n' "$DURATION"

old=$(measure "$WORK/old.sh" old)
new=$(measure "$WORK/new.sh" new)

printf '  %-28s %6s processes  %6.1f/s\n' "before ($BASE_REF)" "$old" "$(echo "$old $DURATION" | awk '{print $1/$2}')"
printf '  %-28s %6s processes  %6.1f/s\n' "after (this branch)" "$new" "$(echo "$new $DURATION" | awk '{print $1/$2}')"

if (( new > 0 )); then
    printf '\n  %.1fx fewer processes while idle\n' "$(echo "$old $new" | awk '{print $1/$2}')"
    printf '  %s fewer per day at this rate\n' \
        "$(echo "$old $new $DURATION" | awk '{printf "%\047d", ($1-$2)/$3*86400}')"
fi
