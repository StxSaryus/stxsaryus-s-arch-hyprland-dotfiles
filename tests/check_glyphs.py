#!/usr/bin/env python3
"""Catch tofu boxes before they reach the bar.

Every icon in this rice is a Nerd Font glyph living in a private use area.
If a codepoint is wrong by one, nothing errors out — the bar simply renders
an empty rectangle. This walks the configs, collects the private-use
codepoints and checks each one against the installed JetBrainsMono Nerd Font.
"""
import pathlib
import subprocess
import sys

try:
    from fontTools.ttLib import TTFont
except ImportError:
    print("  skip fontTools not installed")
    sys.exit(0)

ROOT = pathlib.Path(__file__).resolve().parent.parent

SCAN = [
    "config/waybar/config.jsonc",
    "config/waybar/sys_stats.sh",
    "config/waybar/scripts/lock-icon.sh",
    "config/swaync/config.json",
    "config/local-bin/systemupdate.sh",
    "config/rofi/config.rasi",
    "config/hypr/hyprlock.conf",
]

# Nerd Font glyph homes: the BMP private use area and the two supplementary
# planes the Material Design / Font Awesome sets are mapped into.
PUA_RANGES = [
    (0xE000, 0xF8FF),
    (0xF0000, 0xFFFFD),
    (0x100000, 0x10FFFD),
]

# This rice draws its icons from one family — the Material Design set — so
# stroke weight and optical size match wherever an icon appears. Font
# Awesome and friends live in the BMP private use area; ours do not.
MDI_RANGE = (0xF0001, 0xF1AF0)


def is_icon(cp: int) -> bool:
    return any(lo <= cp <= hi for lo, hi in PUA_RANGES)


def is_material(cp: int) -> bool:
    return MDI_RANGE[0] <= cp <= MDI_RANGE[1]


def font_path() -> str | None:
    try:
        out = subprocess.run(
            ["fc-match", "-f", "%{file}", "JetBrainsMono Nerd Font"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None
    return out or None


def main() -> int:
    path = font_path()
    if not path or "JetBrainsMono" not in path:
        print("  skip JetBrainsMono Nerd Font is not installed on this machine")
        return 0

    font = TTFont(path, fontNumber=0)
    covered = set()
    for table in font["cmap"].tables:
        covered.update(table.cmap.keys())

    used: dict[int, list[str]] = {}
    for rel in SCAN:
        text = (ROOT / rel).read_text(encoding="utf-8")
        for lineno, line in enumerate(text.splitlines(), 1):
            for ch in line:
                cp = ord(ch)
                if is_icon(cp):
                    used.setdefault(cp, []).append(f"{rel}:{lineno}")

    print(f"  {len(used)} icon glyphs used, font covers {len(covered)} codepoints")

    failed = False
    for cp, places in sorted(used.items()):
        if cp not in covered:
            print(f"  FAIL U+{cp:04X} is not in the font — {places[0]}")
            failed = True
        elif not is_material(cp):
            print(f"  FAIL U+{cp:04X} is not a Material Design icon — {places[0]}")
            failed = True
    if failed:
        return 1
    print(f"  ok   every icon is Material Design and resolves in {pathlib.Path(path).name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
