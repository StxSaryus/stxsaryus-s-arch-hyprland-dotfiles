#!/usr/bin/env python3
"""Validate the JSON configs and cross-check the Waybar module list.

Waybar silently drops a module it cannot find a definition for, which looks
exactly like a CSS problem and wastes an afternoon. Comparing the layout
arrays against the defined blocks catches it in a second instead.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Modules Waybar provides itself and that need no block of their own.
BUILTIN_PREFIXES = (
    "hyprland/", "sway/", "wlr/", "river/", "niri/",
    "cpu", "memory", "disk", "temperature", "backlight", "battery",
    "network", "pulseaudio", "wireplumber", "bluetooth", "clock", "tray",
    "idle_inhibitor", "mpris", "keyboard-state", "upower", "power-profiles-daemon",
    "privacy", "systemd-failed-units", "user", "image", "cava",
)


def strip_jsonc(text: str) -> str:
    """Remove // line comments that are not inside a string."""
    out = []
    in_string = False
    escaped = False
    i = 0
    while i < len(text):
        ch = text[i]
        if in_string:
            out.append(ch)
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
            continue
        if ch == "/" and i + 1 < len(text) and text[i + 1] == "/":
            while i < len(text) and text[i] != "\n":
                i += 1
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def load(rel: str):
    text = (ROOT / rel).read_text(encoding="utf-8")
    if rel.endswith(".jsonc"):
        text = strip_jsonc(text)
    return json.loads(text)


def check_waybar(config: dict) -> int:
    failures = 0
    listed = []
    for side in ("modules-left", "modules-center", "modules-right"):
        listed.extend(config.get(side, []))
    for group in [k for k in config if k.startswith("group/")]:
        listed.extend(config[group].get("modules", []))

    for name in listed:
        if name in config:
            continue
        if name.startswith(BUILTIN_PREFIXES):
            continue
        print(f"  FAIL waybar module '{name}' is placed on the bar but never defined")
        failures += 1

    for key in config:
        if key.startswith(("custom/", "group/")) and key not in listed:
            print(f"  FAIL waybar module '{key}' is defined but never placed on the bar")
            failures += 1

    if not failures:
        print(f"  ok   waybar: {len(listed)} modules, all defined and all placed")
    return failures


def main() -> int:
    failures = 0
    for rel in ("config/waybar/config.jsonc", "config/swaync/config.json", "config/nwg-bar/bar.json"):
        try:
            data = load(rel)
        except json.JSONDecodeError as exc:
            print(f"  FAIL {rel}: {exc}")
            failures += 1
            continue
        print(f"  ok   {rel} parses")
        if rel.endswith("config.jsonc"):
            failures += check_waybar(data)

    # swaync widgets must be known names
    swaync = load("config/swaync/config.json")
    known = {"title", "dnd", "label", "mpris", "volume", "backlight", "buttons-grid",
             "menubar", "notifications", "inhibitors"}
    for widget in swaync.get("widgets", []):
        base = re.sub(r"#.*$", "", widget)
        if base not in known:
            print(f"  FAIL swaync widget '{widget}' is not a known widget")
            failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
