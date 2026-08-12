#!/usr/bin/env python3
"""Parse every GTK stylesheet in the rice and report any complaint GTK makes.

Waybar, SwayNC, nwg-bar, Waypaper and GTK itself all read GTK CSS, and all of
them fail quietly: a typo means one rule is dropped and the bar just looks
slightly wrong. Loading the files through GtkCssProvider here turns that into
a test failure instead.
"""
import sys
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gio, Gtk  # noqa: E402

FILES = [
    "config/theme/colors.css",
    "config/waybar/style.css",
    "config/swaync/style.css",
    "config/nwg-bar/style.css",
    "config/waypaper/style.css",
    "config/gtk-3.0/gtk.css",
    "config/gtk-4.0/gtk.css",
]


def check(path: str) -> list[str]:
    errors: list[str] = []
    provider = Gtk.CssProvider()

    def on_error(_provider, section, error):
        line = section.get_start_line() + 1 if section is not None else 0
        errors.append(f"{path}:{line}: {error.message}")

    provider.connect("parsing-error", on_error)
    try:
        provider.load_from_file(Gio.File.new_for_path(path))
    except Exception as exc:  # noqa: BLE001 - GTK raises a bare GError
        errors.append(f"{path}: {exc}")
    return errors


def main() -> int:
    failures: list[str] = []
    for path in FILES:
        problems = check(path)
        if problems:
            failures.extend(problems)
            print(f"  FAIL {path}")
            for line in problems:
                print(f"       {line}")
        else:
            print(f"  ok   {path}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
