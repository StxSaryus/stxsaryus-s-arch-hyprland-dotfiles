# Nocturne — the design system

Everything you see in this rice comes from one file. `palette.conf` holds the
colours; `build-theme.sh` turns them into the four formats the applications
speak. Nothing else in the repo is allowed to contain a colour.

```
palette.conf ──► build-theme.sh ──┬─► colors.css          GTK: waybar, swaync,
                                  │                       nwg-bar, waypaper, gtk3/4
                                  ├─► colors.rasi         rofi
                                  ├─► colors-kitty.conf   kitty
                                  └─► colors-hypr.conf    hyprland, hyprlock
```

## Changing the theme

```bash
$EDITOR config/theme/palette.conf
./config/theme/build-theme.sh
```

The generated files are committed, so the installer never has to run anything.
`./config/theme/build-theme.sh --check` fails if they have drifted, and
`tests/run-tests.sh` runs that check along with one that rejects any colour
under `config/` that is not in the palette.

One exception to the diagram: Waypaper hands its stylesheet to GTK as raw
bytes rather than as a path, so `@import` has nothing to resolve against and
crashes it. `build-theme.sh` writes the palette straight into the marked
block at the top of `config/waypaper/style.css` instead.

## The palette

| Token | Value | Where it shows up |
|-------|-------|-------------------|
| `crust` | `#07080b` | Lock screen, deepest shadows |
| `base` | `#0d0f14` | Terminal and window backgrounds |
| `mantle` | `#11131a` | The bar and panel glass |
| `surface` | `#1a1d26` | Cards, grouped modules, inputs |
| `overlay` | `#262a36` | Hover and pressed states |
| `line` | `#3a4152` | Hairlines, inactive window borders |
| `text` | `#e6e9f0` | Primary text |
| `subtext` | `#b6bdcd` | Module labels, notification bodies |
| `muted` | `#7d8598` | Window titles, placeholders, comments |
| `faint` | `#4d5566` | Inactive workspaces, disabled state |
| `accent` | `#33ccff` | Arch cyan — active workspace, focused border, prompts |
| `green` `yellow` `red` | Catppuccin-derived | Charging, warning, critical |
| `blue` `mauve` `teal` `peach` `pink` | | Terminal palette and accents |

Surfaces get their translucency from the `alpha_*` values in the same file, so
"how much glass" is one number, not eight.

## Geometry

One radius scale, used everywhere:

| | Radius | Applied to |
|---|--------|-----------|
| small | `8px` | Bar pills, launcher rows, buttons, toggles |
| medium | `12px` | Windows, notification cards, grouped modules |
| large | `16px` | The bar itself, launcher, control centre, lock field |

Windows use `6px` inner and `12px` outer gaps with a `2px` border.

## Typography

`JetBrainsMono Nerd Font` throughout, at three sizes: `12px` for secondary
labels, `13px` for everything normal, `15px` for glyph-only buttons.

## Icons

Every icon is a **Material Design** glyph from the Nerd Font — one family, so
stroke weight and optical size match wherever an icon appears. Font Awesome
glyphs live in the BMP private use area; ours do not, and
`tests/check_glyphs.py` fails the build if one sneaks in or if a codepoint is
missing from the font.
