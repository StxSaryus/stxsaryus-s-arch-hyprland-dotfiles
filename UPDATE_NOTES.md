# Dotfiles update notes

Notes shown by the Waybar **Updates** module before you accept a rice update.
Add a short bullet list here whenever you ship plugin/config changes that users
should notice. Newest section first.

---

## 2026-07-19 — Interactive Waybar updates

- Waybar **Updates** now tracks **Arch packages** and **this repo** together.
- Left-click opens a terminal menu: review notes, then choose packages / dotfiles / both / cancel.
- Dotfiles apply is never automatic: confirm → `git pull --ff-only` → `./install.sh --configs`.
- Right-click refreshes the remote check (forces `git fetch`) and redraws the badge.
- Local uncommitted changes in `~/dotfiles` block the pull until you commit or stash.
