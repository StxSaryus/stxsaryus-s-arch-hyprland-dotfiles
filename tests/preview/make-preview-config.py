#!/usr/bin/env python3
"""Turn the real Waybar config into one a headless sway session can run.

The only edits are the compositor-specific modules — sway's workspace and
window modules stand in for Hyprland's. Every other module, every format
string and the whole stylesheet are the ones that ship.

    make-preview-config.py <config.jsonc> <out.jsonc>
"""
import json
import sys
import pathlib

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from check_json import strip_jsonc  # noqa: E402

src, dst = sys.argv[1], sys.argv[2]
config = json.loads(strip_jsonc(pathlib.Path(src).read_text(encoding="utf-8")))

SWAP = {"hyprland/workspaces": "sway/workspaces", "hyprland/window": "sway/window"}

for side in ("modules-left", "modules-center", "modules-right"):
    config[side] = [SWAP.get(name, name) for name in config.get(side, [])]

for old, new in SWAP.items():
    if old in config:
        config[new] = config.pop(old)

# Hyprland's dispatcher is not around to answer these.
config["sway/workspaces"].pop("on-scroll-up", None)
config["sway/workspaces"].pop("on-scroll-down", None)

pathlib.Path(dst).write_text(json.dumps(config, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"wrote {dst}")
