#!/usr/bin/env python3
"""Make sure the configs and the installer agree with each other.

Two ways this rice used to break:

  * a config pointed at ~/.config/something that the repo never shipped
    (hyprlock and nwg-bar were referenced from three places and shipped from
    none), and
  * a file was added under config/ but never added to install.sh, so it only
    worked on the author's machine.

Both are cheap to check and expensive to notice by hand.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# ~/.config/<dir> -> repo directory
CONFIG_DIRS = {
    "hypr": "config/hypr",
    "waybar": "config/waybar",
    "theme": "config/theme",
    "rofi": "config/rofi",
    "kitty": "config/kitty",
    "swaync": "config/swaync",
    "nwg-bar": "config/nwg-bar",
    "waypaper": "config/waypaper",
    "gtk-3.0": "config/gtk-3.0",
    "gtk-4.0": "config/gtk-4.0",
}

SCAN = [
    "config/hypr/hyprland.conf",
    "config/hypr/hyprlock.conf",
    "config/hypr/hypridle.conf",
    "config/waybar/config.jsonc",
    "config/swaync/config.json",
    "config/waypaper/config.ini",
    "config/local-bin/launcher-toggle.sh",
]

# Created at runtime rather than shipped
RUNTIME = {
    "config/waybar/.pinned",
    "config/waypaper/keybindings.ini",
}

# Not linked by install.sh on purpose
NOT_INSTALLED = {
    "config/theme/README.md",
}

PATH_RE = re.compile(r"~/\.(?:config|local/share)/[\w./-]+")


def repo_path_for(reference: str) -> str | None:
    if reference.startswith("~/.local/share/bin/"):
        return "config/local-bin/" + reference.split("/")[-1]
    if reference.startswith("~/.config/"):
        rest = reference[len("~/.config/"):]
        head, _, tail = rest.partition("/")
        if not tail or head not in CONFIG_DIRS:
            return None
        return f"{CONFIG_DIRS[head]}/{tail}"
    return None


def check_referenced_files() -> int:
    failures = 0
    seen = 0
    for rel in SCAN:
        text = (ROOT / rel).read_text(encoding="utf-8")
        for lineno, line in enumerate(text.splitlines(), 1):
            if line.lstrip().startswith("#"):
                continue
            for reference in PATH_RE.findall(line):
                target = repo_path_for(reference)
                if target is None or target in RUNTIME:
                    continue
                seen += 1
                if not (ROOT / target).exists():
                    print(f"  FAIL {rel}:{lineno}: {reference} -> missing {target}")
                    failures += 1
    if not failures:
        print(f"  ok   {seen} ~/.config references all exist in the repo")
    return failures


def check_installer_coverage() -> int:
    installer = (ROOT / "install.sh").read_text(encoding="utf-8")
    failures = 0
    checked = 0
    for path in sorted((ROOT / "config").rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT).as_posix()
        if rel in NOT_INSTALLED:
            continue
        checked += 1
        if path.name not in installer:
            print(f"  FAIL {rel} is never mentioned in install.sh")
            failures += 1
    if not failures:
        print(f"  ok   install.sh covers all {checked} files under config/")
    return failures


def main() -> int:
    failures = check_referenced_files() + check_installer_coverage()
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
