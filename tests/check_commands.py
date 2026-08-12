#!/usr/bin/env python3
"""Every keybind and every click has to run something the installer installs.

A shortcut that calls a binary nobody installed fails the same way a broken
one does: nothing happens, no error, no clue. This walks the Hyprland binds,
the Waybar click and scroll actions, the SwayNC buttons and the nwg-bar
entries, pulls out every command in every pipeline, and checks that each one
is either part of a base Arch install or comes from a package listed in
install.sh.
"""
import json
import pathlib
import re
import shlex
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from check_json import strip_jsonc  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Command -> the package install.sh has to be asking for.
PACKAGES = {
    "hyprctl": "hyprland",
    "hyprlock": "hyprlock",
    "hypridle": "hypridle",
    "hyprpaper": "hyprpaper",
    "hyprpicker": "hyprpicker",
    "waybar": "waybar",
    "swaync": "swaync",
    "swaync-client": "swaync",
    "nwg-bar": "nwg-bar",
    "rofi": "rofi",
    "kitty": "kitty",
    "firefox": "firefox",
    "thunar": "thunar",
    "btop": "btop",
    "fastfetch": "fastfetch",
    "pavucontrol": "pavucontrol",
    "pamixer": "pamixer",
    "playerctl": "playerctl",
    "brightnessctl": "brightnessctl",
    "blueman-manager": "blueman",
    "nm-applet": "network-manager-applet",
    "nm-connection-editor": "network-manager-applet",
    "grim": "grim",
    "slurp": "slurp",
    "swappy": "swappy",
    "cliphist": "cliphist",
    "wl-copy": "wl-clipboard",
    "wl-paste": "wl-clipboard",
    "jq": "jq",
    "notify-send": "libnotify",
    "checkupdates": "pacman-contrib",
    "lsd": "lsd",
    "fzf": "fzf",
    "waypaper": "waypaper-git",
}

# Shipped by a base Arch system, or a shell builtin.
BASE = {
    "bash", "sh", "systemctl", "loginctl", "kill", "xargs", "pkill", "pgrep",
    "setsid", "sleep", "echo", "printf", "read", "true", "cat", "sed", "awk",
    "grep", "wc", "date", "env", "command", "exec",
}

# Provided by the repo itself rather than a package.
OWN_SCRIPTS = {"waypaper-toggle.sh", "launcher-toggle.sh", "systemupdate.sh",
               "lock-icon.sh", "lock-toggle.sh", "sys_stats.sh", "osd.sh",
               "waybar-autohide.sh", "wallpaper-sync.sh", "apply-dark-theme.sh"}

# Optional at runtime: the scripts check for these before using them.
OPTIONAL = {"nvidia-smi", "yay", "paru", "dunstify"}


def commands_in(snippet: str) -> list[str]:
    """First word of every stage of a (possibly piped) command line."""
    found = []
    snippet = re.sub(r"\$\((?:[^()]|\([^()]*\))*\)", " ", snippet)   # drop $(...)
    for stage in re.split(r"\||&&|;", snippet):
        stage = stage.strip()
        if not stage:
            continue
        try:
            words = shlex.split(stage)
        except ValueError:
            words = stage.split()
        while words and ("=" in words[0] and not words[0].startswith("/")):
            words.pop(0)      # strip VAR=value prefixes
        if not words:
            continue
        first = words[0]
        if first in ("sh", "bash") and "-c" in words:
            inner = words[words.index("-c") + 1] if len(words) > words.index("-c") + 1 else ""
            found.extend(commands_in(inner))
            continue
        found.append(first)
    return found


def collect() -> dict[str, list[str]]:
    """command -> where it is referenced"""
    uses: dict[str, list[str]] = {}

    def note(cmd: str, where: str) -> None:
        uses.setdefault(cmd, []).append(where)

    # Hyprland: bind ... , exec, <command>   and   exec-once = <command>
    hypr = (ROOT / "config/hypr/hyprland.conf").read_text(encoding="utf-8")
    variables = dict(re.findall(r"^\$(\w+)\s*=\s*(.+)$", hypr, re.M))
    for lineno, line in enumerate(hypr.splitlines(), 1):
        line = line.strip()
        snippet = None
        if line.startswith("exec-once"):
            snippet = line.split("=", 1)[1]
        elif re.match(r"^bind[a-z]*\s*=", line) and ", exec," in line:
            snippet = line.split(", exec,", 1)[1]
        if snippet is None:
            continue
        for name, value in variables.items():
            snippet = snippet.replace(f"${name}", value)
        for cmd in commands_in(snippet):
            note(cmd, f"hyprland.conf:{lineno}")

    # Waybar: exec and every on-click / on-scroll action
    waybar = json.loads(strip_jsonc((ROOT / "config/waybar/config.jsonc").read_text(encoding="utf-8")))
    for module, config in waybar.items():
        if not isinstance(config, dict):
            continue
        # The workspaces module takes an action name here ("activate"),
        # not a shell command.
        if module.endswith("/workspaces"):
            config = {k: v for k, v in config.items() if k != "on-click"}
        for key, value in config.items():
            if isinstance(value, str) and (key.startswith(("on-click", "on-scroll")) or key == "exec"):
                for cmd in commands_in(value):
                    note(cmd, f"waybar {module}.{key}")

    # SwayNC buttons
    swaync = json.loads((ROOT / "config/swaync/config.json").read_text(encoding="utf-8"))
    for action in swaync.get("widget-config", {}).get("buttons-grid", {}).get("actions", []):
        for cmd in commands_in(action.get("command", "")):
            note(cmd, f"swaync button {action.get('label', '?')}")

    # nwg-bar session menu
    for entry in json.loads((ROOT / "config/nwg-bar/bar.json").read_text(encoding="utf-8")):
        for cmd in commands_in(entry.get("exec", "")):
            note(cmd, f"nwg-bar {entry.get('label', '?')}")

    # The shipped scripts, too: a bind that runs one of ours is only as good
    # as what that script calls. Matching known names keeps this free of
    # false positives, at the cost of not spotting a brand new tool.
    known = set(PACKAGES) | OPTIONAL
    for script in sorted((ROOT / "config").rglob("*.sh")):
        text = script.read_text(encoding="utf-8")
        for lineno, line in enumerate(text.splitlines(), 1):
            if line.lstrip().startswith("#"):
                continue
            for name in known:
                if re.search(rf"(?<![\w./-]){re.escape(name)}(?![\w./-])", line):
                    note(name, f"{script.relative_to(ROOT)}:{lineno}")

    return uses


def main() -> int:
    installer = (ROOT / "install.sh").read_text(encoding="utf-8")
    uses = collect()
    failures = 0

    for cmd in sorted(uses):
        where = uses[cmd][0]
        name = cmd.rsplit("/", 1)[-1]

        if name in OWN_SCRIPTS or name in BASE or name in OPTIONAL:
            continue
        if cmd.startswith("~/") or cmd.startswith("/"):
            continue

        package = PACKAGES.get(name)
        if package is None:
            print(f"  FAIL {name} ({where}) is not in the command/package table")
            failures += 1
            continue
        if not re.search(rf"(?<![\w-]){re.escape(package)}(?![\w-])", installer):
            print(f"  FAIL {name} ({where}) needs {package}, which install.sh never installs")
            failures += 1

    if failures:
        return 1
    print(f"  ok   {len(uses)} distinct commands behind the binds and clicks, all installed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
