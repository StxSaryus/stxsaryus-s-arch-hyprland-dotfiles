#!/usr/bin/env bash
#
# Everything in this repo that can be checked without an actual Hyprland
# session. Run it before pushing:
#
#     ./tests/run-tests.sh
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0
FAIL=0
FAILED_NAMES=()

run() {
    local name="$1"; shift
    printf '\n%b── %s ──%b\n' "$BOLD" "$name" "$NC"
    if "$@"; then
        printf '%b✔ %s%b\n' "$GREEN" "$name" "$NC"
        (( PASS++ ))
    else
        printf '%b✘ %s%b\n' "$RED" "$name" "$NC"
        (( FAIL++ ))
        FAILED_NAMES+=("$name")
    fi
}

scripts() {
    # Tracked and not-yet-committed alike, so a new script is checked before
    # it lands rather than after.
    git ls-files --cached --others --exclude-standard '*.sh' 2>/dev/null \
        || find . -name '*.sh' -not -path './.git/*'
}

# ── 1. Shell syntax ──────────────────────────────────────────
test_syntax() {
    local f rc=0
    while read -r f; do
        bash -n "$f" || { echo "  FAIL $f"; rc=1; }
    done < <(scripts)
    bash -n bash/.bashrc || { echo "  FAIL bash/.bashrc"; rc=1; }
    if command -v zsh >/dev/null 2>&1; then
        zsh -n zsh/.zshrc || { echo "  FAIL zsh/.zshrc"; rc=1; }
    else
        printf '  %bskip zsh is not installed, .zshrc unchecked%b\n' "$YELLOW" "$NC"
    fi
    (( rc == 0 )) && echo "  ok   every shell script and both shell rc files parse"
    return $rc
}

# ── 2. Shellcheck ────────────────────────────────────────────
test_shellcheck() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        printf '  %bskip shellcheck is not installed%b\n' "$YELLOW" "$NC"
        return 0
    fi
    local files=()
    mapfile -t files < <(scripts)
    if shellcheck -x -S warning "${files[@]}"; then
        echo "  ok   shellcheck clean at warning level (${#files[@]} scripts)"
        return 0
    fi
    return 1
}

# ── 3. Generated theme files match the palette ───────────────
test_theme_sync() {
    ./config/theme/build-theme.sh --check
}

# ── 4-7. Static config checks ────────────────────────────────
test_json()       { python3 tests/check_json.py; }
test_palette()    { python3 tests/check_palette.py; }
test_glyphs()     { python3 tests/check_glyphs.py; }
test_css()        { python3 tests/check_css.py; }
test_references() { python3 tests/check_references.py; }
test_commands()   { python3 tests/check_commands.py; }

# ── 8. Hyprland config sanity ────────────────────────────────
test_hyprland() {
    local conf="config/hypr/hyprland.conf" rc=0

    # Every $variable used has to be declared somewhere in the file or in
    # the sourced palette.
    local declared used var
    declared="$(grep -oE '^\$[A-Za-z]+' "$conf" | tr -d '$'; grep -oE '^\$[A-Za-z]+' config/theme/colors-hypr.conf | tr -d '$')"
    used="$(grep -oE '\$[A-Za-z]+' "$conf" | tr -d '$' | sort -u)"
    for var in $used; do
        if ! grep -qx "$var" <<<"$declared"; then
            echo "  FAIL \$$var is used but never declared"
            rc=1
        fi
    done

    # Braces have to balance or Hyprland refuses the whole file.
    local opens closes
    opens="$(grep -c '{[[:space:]]*$' "$conf")"
    closes="$(grep -c '^[[:space:]]*}' "$conf")"
    if [[ "$opens" != "$closes" ]]; then
        echo "  FAIL unbalanced braces: $opens open, $closes close"
        rc=1
    fi

    # Duplicate keybindings shadow each other silently.
    local dupes
    dupes="$(grep -oE '^bind[a-z]* = [^,]+, [^,]+,' "$conf" | sort | uniq -d)"
    if [[ -n "$dupes" ]]; then
        echo "  FAIL duplicate keybinding:"
        echo "$dupes" | sed 's/^/       /'
        rc=1
    fi

    (( rc == 0 )) && echo "  ok   variables declared, braces balanced, no duplicate binds"
    return $rc
}

# ── 9. Installer, into a throwaway HOME ──────────────────────
test_installer() {
    local stage rc=0
    stage="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$stage'" RETURN

    # Fingerprint the checkout so we can prove the installer never writes
    # back into it through a symlink.
    find config zsh bash -type f -exec md5sum {} + | sort >"$stage/before.md5"

    if ! HOME="$stage" ./install.sh --configs >"$stage/install.log" 2>&1; then
        echo "  FAIL install.sh --configs exited non-zero"
        tail -20 "$stage/install.log" | sed 's/^/       /'
        return 1
    fi

    local broken
    broken="$(find "$stage" -xtype l 2>/dev/null)"
    if [[ -n "$broken" ]]; then
        echo "  FAIL broken symlinks after install:"
        echo "$broken" | sed 's/^/       /'
        rc=1
    fi

    local expected=(
        ".config/hypr/hyprland.conf" ".config/hypr/hyprlock.conf"
        ".config/hypr/hypridle.conf" ".config/hypr/osd.sh"
        ".config/hypr/hyprpaper.conf"
        ".config/theme/colors.css" ".config/theme/palette.conf"
        ".config/waybar/config.jsonc" ".config/waybar/style.css"
        ".config/waybar/scripts/lock-icon.sh"
        ".config/rofi/config.rasi" ".config/kitty/kitty.conf"
        ".config/swaync/style.css" ".config/nwg-bar/bar.json"
        ".config/nwg-bar/style.css" ".config/waypaper/style.css"
        ".config/gtk-3.0/gtk.css" ".config/gtk-4.0/gtk.css"
        ".local/share/bin/systemupdate.sh" ".zshrc" ".bashrc"
    )
    local f
    for f in "${expected[@]}"; do
        [[ -e "$stage/$f" ]] || { echo "  FAIL not installed: ~/$f"; rc=1; }
    done

    # Files the apps write to must be real copies, never links into the repo.
    for f in ".config/hypr/hyprpaper.conf" ".config/waypaper/config.ini"; do
        if [[ -L "$stage/$f" ]]; then
            echo "  FAIL ~/$f is a symlink; the app would write into the git checkout"
            rc=1
        fi
    done

    # Stylesheets must still resolve their imports from the installed layout.
    local css
    for css in ".config/waybar/style.css" ".config/swaync/style.css" ".config/nwg-bar/style.css"; do
        if ! python3 - "$stage/$css" <<'PY'
import sys, gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gio, Gtk
errs = []
p = Gtk.CssProvider()
p.connect("parsing-error", lambda pr, s, e: errs.append(e.message))
try:
    p.load_from_file(Gio.File.new_for_path(sys.argv[1]))
except Exception as exc:
    errs.append(str(exc))
if errs:
    print("\n".join(errs))
sys.exit(1 if errs else 0)
PY
        then
            echo "  FAIL ~/$css does not parse from the installed layout"
            rc=1
        fi
    done

    if ! grep -q '^\$terminal = kitty$' "$stage/.config/hypr/hyprland.conf"; then
        echo "  FAIL hyprland.conf default terminal was not written"
        rc=1
    fi

    # A scripted install with different choices has to rewrite both the
    # command and the key.
    local stage2
    stage2="$(mktemp -d)"
    HOME="$stage2" TERMINAL_CMD="alacritty" KEY_TERMINAL="RETURN" \
        ./install.sh --configs >"$stage2/install.log" 2>&1
    if ! grep -q '^\$terminal = alacritty$' "$stage2/.config/hypr/hyprland.conf"; then
        echo "  FAIL TERMINAL_CMD override was not applied"
        rc=1
    fi
    if ! grep -q '^bind = \$mainMod, RETURN, exec, \$terminal$' "$stage2/.config/hypr/hyprland.conf"; then
        echo "  FAIL KEY_TERMINAL override was not applied"
        rc=1
    fi
    rm -rf "$stage2"

    find config zsh bash -type f -exec md5sum {} + | sort >"$stage/after.md5"
    if ! diff -q "$stage/before.md5" "$stage/after.md5" >/dev/null; then
        echo "  FAIL install.sh changed files inside the checkout:"
        diff "$stage/before.md5" "$stage/after.md5" | sed 's/^/       /'
        rc=1
    fi

    (( rc == 0 )) && echo "  ok   configs install, imports resolve, overrides apply, repo untouched"
    return $rc
}

# ── 10. Waybar / autohide behaviour, with Hyprland stubbed out ──
test_autohide() {
    bash tests/test-autohide.sh
}

run "shell syntax"        test_syntax
run "shellcheck"          test_shellcheck
run "theme in sync"       test_theme_sync
run "json configs"        test_json
run "palette discipline"  test_palette
run "nerd font glyphs"    test_glyphs
run "gtk stylesheets"     test_css
run "cross references"    test_references
run "bind/click commands" test_commands
run "hyprland config"     test_hyprland
run "installer"           test_installer
run "waybar autohide"     test_autohide

printf '\n%b────────────────────────────%b\n' "$BOLD" "$NC"
printf '%b%d passed%b' "$GREEN" "$PASS" "$NC"
if (( FAIL )); then
    printf ', %b%d failed%b: %s\n' "$RED" "$FAIL" "$NC" "${FAILED_NAMES[*]}"
    exit 1
fi
printf ', 0 failed\n'
