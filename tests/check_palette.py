#!/usr/bin/env python3
"""Guard the single-palette rule.

Any colour that appears in a config file has to be one of the colours in
config/theme/palette.conf, and raw rgb()/rgba() triples are not allowed
outside the generated theme files — those are what the tokens are for.
This is what keeps the rice looking like one thing instead of eight.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PALETTE = ROOT / "config/theme/palette.conf"

# Generated from the palette, so allowed to contain literal colours.
GENERATED = {
    "config/theme/build-theme.sh",
    "config/theme/colors.css",
    "config/theme/colors.rasi",
    "config/theme/colors-kitty.conf",
    "config/theme/colors-hypr.conf",
}

SCAN_SUFFIXES = {".css", ".rasi", ".conf", ".jsonc", ".json", ".ini", ".sh"}

HEX = re.compile(r"#{1,2}([0-9a-fA-F]{6})(?![0-9a-fA-F])")
FUNC = re.compile(r"\brgba?\(\s*\d")


def palette_colours() -> set[str]:
    colours = set()
    for line in PALETTE.read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if "=" not in line:
            continue
        value = line.split("=", 1)[1].strip()
        if re.fullmatch(r"[0-9a-fA-F]{6}", value):
            colours.add(value.lower())
    return colours


def main() -> int:
    allowed = palette_colours()
    if not allowed:
        print("  FAIL could not read any colours from palette.conf")
        return 1
    print(f"  palette defines {len(allowed)} colours")

    failures = 0
    for path in sorted((ROOT / "config").rglob("*")):
        if not path.is_file() or path.suffix not in SCAN_SUFFIXES:
            continue
        rel = path.relative_to(ROOT).as_posix()
        if rel in GENERATED:
            continue

        text = path.read_text(encoding="utf-8", errors="replace")
        for match in HEX.finditer(text):
            value = match.group(1).lower()
            if value not in allowed:
                line = text.count("\n", 0, match.start()) + 1
                print(f"  FAIL {rel}:{line}: #{value} is not in palette.conf")
                failures += 1
        for match in FUNC.finditer(text):
            line = text.count("\n", 0, match.start()) + 1
            print(f"  FAIL {rel}:{line}: raw {match.group(0)}...) — use a theme token")
            failures += 1

    if failures:
        print(f"  {failures} colour(s) outside the palette")
        return 1
    print("  ok   every colour in config/ comes from palette.conf")
    return 0


if __name__ == "__main__":
    sys.exit(main())
