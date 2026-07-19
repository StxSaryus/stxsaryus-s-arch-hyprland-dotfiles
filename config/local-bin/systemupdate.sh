#!/usr/bin/env bash
# Waybar updates module: Arch packages + this rice's dotfiles.
# Never applies updates automatically — always asks in a terminal,
# shows UPDATE_NOTES.md + pending commit messages for rice updates.

set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/stxsaryus-updates"
FETCH_STAMP="$CACHE_DIR/dotfiles-fetch"
FETCH_MAX_AGE="${DOTFILES_FETCH_MAX_AGE:-21600}" # 6 hours
UPSTREAM_FALLBACK="origin/main"

json_escape() {
    local s=${1-}
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    s=${s//$'\t'/\\t}
    printf '%s' "$s"
}

resolve_dotfiles_dir() {
    local self repo
    self=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")
    repo=$(cd "$(dirname "$self")/../.." 2>/dev/null && pwd) || repo=""
    if [[ -n "$repo" && -d "$repo/.git" && -f "$repo/install.sh" ]]; then
        printf '%s' "$repo"
        return 0
    fi
    if [[ -d "$HOME/dotfiles/.git" && -f "$HOME/dotfiles/install.sh" ]]; then
        printf '%s' "$HOME/dotfiles"
        return 0
    fi
    return 1
}

refresh_waybar() {
    pkill -RTMIN+20 waybar 2>/dev/null || true
}

ensure_arch() {
    [[ -f /etc/arch-release ]]
}

pick_aur_helper() {
    if command -v paru &>/dev/null; then
        printf 'paru'
    else
        printf 'yay'
    fi
}

count_packages() {
    local aurhlpr ofc=0 aur=0
    aurhlpr=$(pick_aur_helper)
    if command -v "$aurhlpr" >/dev/null 2>&1; then
        aur=$("$aurhlpr" -Qua 2>/dev/null | wc -l)
    fi
    if command -v checkupdates >/dev/null 2>&1; then
        ofc=$(
            while pgrep -x checkupdates >/dev/null; do sleep 1; done
            checkupdates 2>/dev/null | wc -l
        )
    fi
    ofc=${ofc//[[:space:]]/}
    aur=${aur//[[:space:]]/}
    ofc=${ofc:-0}
    aur=${aur:-0}
    printf '%s %s' "$ofc" "$aur"
}

dotfiles_upstream_ref() {
    local repo=$1 upstream
    upstream=$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
    if [[ -n "$upstream" ]]; then
        printf '%s' "$upstream"
        return 0
    fi
    if git -C "$repo" rev-parse --verify "$UPSTREAM_FALLBACK" >/dev/null 2>&1; then
        printf '%s' "$UPSTREAM_FALLBACK"
        return 0
    fi
    return 1
}

maybe_fetch_dotfiles() {
    local repo=$1 force=${2:-0} now age
    mkdir -p "$CACHE_DIR"
    now=$(date +%s)
    if [[ "$force" -eq 0 && -f "$FETCH_STAMP" ]]; then
        age=$((now - $(cat "$FETCH_STAMP" 2>/dev/null || echo 0)))
        if [[ "$age" -lt "$FETCH_MAX_AGE" ]]; then
            return 0
        fi
    fi
    # Quiet network fetch; never fail the Waybar poll if offline.
    if git -C "$repo" fetch --quiet --prune 2>/dev/null; then
        printf '%s' "$now" >"$FETCH_STAMP"
    fi
}

count_dotfiles_behind() {
    local repo=$1 force=${2:-0} upstream behind
    maybe_fetch_dotfiles "$repo" "$force"
    upstream=$(dotfiles_upstream_ref "$repo") || {
        printf '0'
        return 0
    }
    behind=$(git -C "$repo" rev-list --count "HEAD..$upstream" 2>/dev/null || echo 0)
    behind=${behind//[[:space:]]/}
    printf '%s' "${behind:-0}"
}

dotfiles_dirty() {
    local repo=$1
    [[ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]]
}

print_update_notes() {
    local repo=$1 upstream notes_file
    notes_file="$repo/UPDATE_NOTES.md"
    printf '\n%s\n' "── Dotfiles update notes ──"
    if [[ -f "$notes_file" ]]; then
        # First ~40 non-empty lines after the title keep the prompt readable.
        awk '
            NR == 1 && /^#/ { next }
            /^[[:space:]]*$/ { if (printed) blank++; next }
            {
                if (blank && printed) print "";
                blank = 0;
                print;
                printed++;
                if (printed >= 40) exit
            }
        ' "$notes_file"
        printf '\n'
    else
        printf '%s\n\n' "(No UPDATE_NOTES.md in repo yet.)"
    fi

    upstream=$(dotfiles_upstream_ref "$repo") || return 0
    printf '%s\n' "── Pending commits ($upstream) ──"
    if git -C "$repo" rev-list --count "HEAD..$upstream" 2>/dev/null | grep -qx '0'; then
        printf '%s\n' "(none)"
    else
        git -C "$repo" log --pretty=format:'  • %h %s' --no-decorate "HEAD..$upstream" 2>/dev/null | head -n 20
        printf '\n'
    fi
}

confirm() {
    local prompt=${1:-Continue?} answer
    read -r -p "$prompt [y/N]: " answer || return 1
    [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]
}

apply_packages() {
    local aurhlpr
    aurhlpr=$(pick_aur_helper)
    printf '\n%s\n' "── Package update ($aurhlpr -Syu) ──"
    if ! confirm "Apply system package updates now?"; then
        printf '%s\n' "Skipped package updates."
        return 0
    fi
    command -v fastfetch >/dev/null && fastfetch || true
    "$aurhlpr" -Syu
}

apply_dotfiles() {
    local repo=$1 mode=${2:-show-notes} upstream
    if [[ "$mode" != "skip-notes" ]]; then
        printf '\n'
        print_update_notes "$repo"
        printf '\n'
    fi

    if dotfiles_dirty "$repo"; then
        printf '%s\n' "Dotfiles repo has local changes — refusing to pull."
        printf '%s\n' "Commit/stash them in $repo, then try again."
        return 1
    fi

    if ! confirm "Apply these dotfiles updates (git pull + install.sh --configs)?"; then
        printf '%s\n' "Skipped dotfiles updates."
        return 0
    fi

    upstream=$(dotfiles_upstream_ref "$repo") || {
        printf '%s\n' "No upstream tracking branch found."
        return 1
    }

    # Re-fetch once before applying so notes match what we pull.
    maybe_fetch_dotfiles "$repo" 1
    if ! git -C "$repo" pull --ff-only; then
        printf '%s\n' "git pull --ff-only failed. Resolve manually in $repo."
        return 1
    fi

    if [[ -x "$repo/install.sh" ]]; then
        "$repo/install.sh" --configs
    else
        printf '%s\n' "install.sh missing or not executable."
        return 1
    fi

    printf '\n%s\n' "Dotfiles updated. Reloading Waybar…"
    pkill -x waybar 2>/dev/null || true
    sleep 0.3
    if command -v hyprctl >/dev/null; then
        hyprctl dispatch exec waybar >/dev/null 2>&1 || true
    else
        waybar >/dev/null 2>&1 &
    fi
}

interactive_update() {
    trap 'refresh_waybar' EXIT

    local ofc=0 aur=0 pkg=0 df=0 repo="" choice
    if ensure_arch; then
        read -r ofc aur < <(count_packages)
        pkg=$((ofc + aur))
    fi
    if repo=$(resolve_dotfiles_dir); then
        df=$(count_dotfiles_behind "$repo" 1)
    fi

    clear 2>/dev/null || true
    printf '%s\n' "══════════════════════════════════════"
    printf '%s\n' "  StxSaryus updates"
    printf '%s\n' "══════════════════════════════════════"
    if ensure_arch; then
        printf '  Packages : %s  (Official %s · AUR %s)\n' "$pkg" "$ofc" "$aur"
    else
        printf '  Packages : (Arch only — skipped)\n'
    fi
    if [[ -n "$repo" ]]; then
        printf '  Dotfiles : %s commit(s) behind  [%s]\n' "$df" "$repo"
    else
        printf '  Dotfiles : (repo not found)\n'
    fi
    printf '%s\n\n' "══════════════════════════════════════"

    if [[ "$pkg" -eq 0 && "$df" -eq 0 ]]; then
        printf '%s\n' "Everything is up to date."
        read -n 1 -r -p "Press any key to close..."
        return 0
    fi

    if [[ "$df" -gt 0 && -n "$repo" ]]; then
        print_update_notes "$repo"
        printf '\n'
    fi

    if [[ "$pkg" -gt 0 && "$df" -gt 0 && -n "$repo" ]]; then
        printf '%s\n' "What do you want to update?"
        printf '  [1] Packages only\n'
        printf '  [2] Dotfiles only (notes above)\n'
        printf '  [3] Both\n'
        printf '  [q] Cancel\n\n'
        read -r -p "Choice: " choice || choice=q
        case "${choice,,}" in
            1) apply_packages ;;
            2) apply_dotfiles "$repo" skip-notes ;;
            3)
                apply_packages
                apply_dotfiles "$repo" skip-notes
                ;;
            q | "") printf '%s\n' "Cancelled." ;;
            *) printf '%s\n' "Unknown choice — cancelled." ;;
        esac
    elif [[ "$df" -gt 0 && -n "$repo" ]]; then
        printf '%s\n' "Dotfiles updates are ready (not applied yet)."
        printf '  [y] Confirm & apply rice update\n'
        printf '  [q] Cancel\n\n'
        read -r -p "Choice: " choice || choice=q
        case "${choice,,}" in
            y | yes) apply_dotfiles "$repo" skip-notes ;;
            *) printf '%s\n' "Cancelled." ;;
        esac
    else
        printf '%s\n' "Package updates are ready (not applied yet)."
        printf '  [y] Confirm & update packages\n'
        printf '  [q] Cancel\n\n'
        read -r -p "Choice: " choice || choice=q
        case "${choice,,}" in
            y | yes) apply_packages ;;
            *) printf '%s\n' "Cancelled." ;;
        esac
    fi

    printf '\n'
    read -n 1 -r -p "Press any key to close..."
}

emit_waybar_json() {
    local ofc=0 aur=0 pkg=0 df=0 repo="" text="" tooltip="" parts=()

    if ensure_arch; then
        read -r ofc aur < <(count_packages)
        pkg=$((ofc + aur))
    fi

    if repo=$(resolve_dotfiles_dir); then
        df=$(count_dotfiles_behind "$repo" 0)
    fi

    if [[ "$pkg" -gt 0 ]]; then
        parts+=("󰮯 $pkg")
        tooltip+="󱓽 Official $ofc"$'\n'"󱓾 AUR $aur"
    fi
    if [[ "$df" -gt 0 ]]; then
        parts+=("󰊢 $df")
        [[ -n "$tooltip" ]] && tooltip+=$'\n'
        tooltip+="󰊢 Dotfiles $df commit(s) behind"
    fi

    if [[ ${#parts[@]} -eq 0 ]]; then
        printf '%s\n' '{"text":"","tooltip":"Packages & dotfiles are up to date"}'
        return 0
    fi

    text=$(IFS=' '; echo "${parts[*]}")
    if [[ "$df" -gt 0 ]]; then
        tooltip+=$'\nClick → review notes & confirm'
    else
        tooltip+=$'\nClick → confirm package update'
    fi
    tooltip+=$'\nRight-click → refresh check'
    printf '{"text":"%s","tooltip":"%s"}\n' "$(json_escape "$text")" "$(json_escape "$tooltip")"
}

cmd=${1:-status}

case "$cmd" in
    up)
        # Interactive confirm UI in a terminal (never auto-applies).
        kitty --title systemupdate "$0" _interactive
        ;;
    _interactive)
        interactive_update
        ;;
    refresh)
        # Force a fresh git fetch + Waybar redraw (right-click).
        repo=""
        if repo=$(resolve_dotfiles_dir); then
            maybe_fetch_dotfiles "$repo" 1
        fi
        refresh_waybar
        ;;
    upgrade)
        # Plain CLI counts (kept for scripts / debugging).
        if ensure_arch; then
            read -r ofc aur < <(count_packages)
            printf "[Official] %-10s\n[AUR]      %-10s\n" "$ofc" "$aur"
        fi
        if repo=$(resolve_dotfiles_dir); then
            df=$(count_dotfiles_behind "$repo" 0)
            printf "[Dotfiles] %-10s\n" "$df"
        fi
        ;;
    status | "")
        emit_waybar_json
        ;;
    *)
        printf 'Usage: %s [status|up|refresh|upgrade]\n' "$(basename "$0")" >&2
        exit 2
        ;;
esac
