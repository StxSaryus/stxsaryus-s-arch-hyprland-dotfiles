#!/usr/bin/env bash
#
# Times the Waybar stats widget, which Waybar re-runs every few seconds for
# as long as you are logged in.
#
#   ./tests/bench-sysstats.sh [runs] [git-ref-for-the-old-version]
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNS="${1:-20}"
BASE_REF="${2:-origin/main}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export XDG_RUNTIME_DIR="$WORK"

git -C "$ROOT" show "$BASE_REF:config/waybar/sys_stats.sh" >"$WORK/old.sh" 2>/dev/null || {
    echo "cannot read the previous version from $BASE_REF" >&2
    exit 1
}
cp "$ROOT/config/waybar/sys_stats.sh" "$WORK/new.sh"

time_script() {
    local script="$1" i start end
    bash "$script" >/dev/null 2>&1   # warm up any caches
    start=$(date +%s%N)
    for (( i = 0; i < RUNS; i++ )); do
        bash "$script" >/dev/null 2>&1
    done
    end=$(date +%s%N)
    echo $(( (end - start) / 1000000 ))
}

printf 'Average of %s refreshes of the Waybar stats module\n\n' "$RUNS"

old_ms=$(time_script "$WORK/old.sh")
new_ms=$(time_script "$WORK/new.sh")

printf '  %-28s %6s ms total  %6.1f ms per refresh\n' "before ($BASE_REF)" "$old_ms" \
    "$(echo "$old_ms $RUNS" | awk '{print $1/$2}')"
printf '  %-28s %6s ms total  %6.1f ms per refresh\n' "after (this branch)" "$new_ms" \
    "$(echo "$new_ms $RUNS" | awk '{print $1/$2}')"

if (( new_ms > 0 )); then
    printf '\n  %.1fx faster\n' "$(echo "$old_ms $new_ms" | awk '{print $1/$2}')"
fi

echo
echo "Output of the new module:"
bash "$WORK/new.sh" | sed 's/^/  /'
