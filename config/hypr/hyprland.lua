-- ============================================================
-- --- StxSaryus EDITION v1.0 | Arch Linux | NVIDIA 1050 Ti ---
-- --- Modern Hyprland 0.57+ Lua Configuration              ---
-- ============================================================

------------------
---- MONITORS ----
------------------

-- 1. MONITOR (1920x1080 @ 60Hz)
hl.monitor({
    output   = "",
    mode     = "highres",
    position = "auto",
    scale    = 1,
})

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- 2. GPU & HARDWARE ENVIRONMENT (Managed dynamically by Hardware Wizard)
local home = os.getenv("HOME")
local config_dir = home .. "/.config/hypr"
package.path = config_dir .. "/?.lua;" .. package.path
pcall(require, "gpu-env")

-- Qt Wayland + multimedia (for Qt apps and media issues)
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

-- System-wide dark theme (GTK3/4 + portals)
hl.env("GTK_THEME", "adw-gtk3-dark")
hl.env("GTK_ICON_THEME_NAME", "Papirus-Dark")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-------------------
---- AUTOSTART ----
-------------------

-- 3. AUTOSTART (only essentials)
hl.on("hyprland.start", function ()
    -- Prefer dark for libadwaita / portals
    hl.exec_cmd(config_dir .. "/apply-dark-theme.sh")
    -- Sync waypaper's last choice to hyprpaper.conf so wallpaper persists across reboots
    hl.exec_cmd(config_dir .. "/wallpaper-sync.sh")
    hl.exec_cmd("waypaper")
    hl.exec_cmd("systemctl --user start xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk")
    hl.exec_cmd("waybar -c " .. home .. "/.config/waybar/config.jsonc -s " .. home .. "/.config/waybar/style.css")
    hl.exec_cmd("bash -c '" .. config_dir .. "/waybar-autohide.sh &'")
    hl.exec_cmd("swaync")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("systemctl --user start obex")
    hl.exec_cmd(home .. "/.local/share/bin/bt-headset.sh")
end)

---------------
---- INPUT ----
---------------

-- 4. INPUT & KEYBOARD (English US)
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
        },
    },
})

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- 5. APPEARANCE (Elegant & modern)
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = "rgba(33ccffee)", -- Arch Mavisi
            inactive_border = "rgba(595959aa)",
        },
        layout = "dwindle",
        allow_tearing = true,
    },

    decoration = {
        rounding = 10,
        blur = {
            enabled = false,
            size = 3,
            passes = 1,
        },
        shadow = {
            enabled = false, -- Disabled to reduce GPU load on 1050 Ti
        },
    },

    misc = {
        disable_watchdog_warning = 1,
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },

    dwindle = {
        preserve_split = true,
    },

    animations = {
        enabled = true,
    },
})

-- 6. ANIMATIONS (single clean block)
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("bounce",   { type = "bezier", points = { {0.1, 1},   {0.1, 1.1} } })

-- Standard animations
hl.animation({ leaf = "windows",          enabled = true, speed = 5,  bezier = "bounce",   style = "slide" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 5,  bezier = "bounce",   style = "slide" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 5,  bezier = "default",  style = "popin 80%" })
hl.animation({ leaf = "border",           enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade",             enabled = true, speed = 5,  bezier = "default" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 5,  bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5,  bezier = "myBezier", style = "slidevert" })

---------------------
---- KEYBINDINGS ----
---------------------

-- 7. SHORTCUTS (SUPER = Win key)
local mainMod = "SUPER"

hl.bind("SHIFT + F11", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl activewindow -j | jq -r 'select(.pid > 1) | .pid' | xargs -r kill -9"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("dolphin"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(home .. "/.local/share/bin/launcher-toggle.sh"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- --- NAVIGATION AND WORKSPACE MANAGEMENT ---

-- A. Move focus with arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- B. Switch workspace with Super + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- C. Move window and follow it (Super + Shift + scroll)
hl.bind(mainMod .. " + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "e-1" }))

-- D, E, F. Workspaces 1-10
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    -- D. Super + number to change workspace
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    -- E. Super + Alt + number to send window silently
    hl.bind(mainMod .. " + ALT + " .. key,   hl.dsp.window.move({ workspace = i, follow = false }))
    -- F. Super + Shift + number to move window and follow it
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
end

-- G. Mouse move/resize window (SUPER + left/right click)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- --- HP Omen FN keys (brightness + audio) ---

-- Brightness (Fn + sun keys) + OSD notification
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(config_dir .. "/brightness-osd.sh up"),   { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(config_dir .. "/brightness-osd.sh down"), { locked = true })

-- Audio (Fn + speaker keys)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("pamixer -i 5"),               { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("pamixer -d 5"),               { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("pamixer -t"),                  { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("pamixer --default-source -t"), { locked = true })

-- Media keys (play / next / prev / stop)
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"),        { locked = true })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"),        { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),              { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),          { locked = true })
hl.bind("XF86AudioStop",         hl.dsp.exec_cmd("playerctl stop"),              { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Pencerelerin izinsiz tam ekran / maximize moduna gecip ekrani kaplamasini engelle
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Opacity rules for media & chat apps
hl.window_rule({
    name = "spotify-opacity",
    match = { class = "^(Spotify)$" },
    opacity = "0.82 override 0.82 override",
})

hl.window_rule({
    name = "discord-opacity",
    match = { class = "^(discord|Discord)$" },
    opacity = "0.82 override 0.82 override",
})

hl.window_rule({
    name = "vesktop-opacity",
    match = { class = "^(vesktop|Vesktop)$" },
    opacity = "0.82 override 0.82 override",
})

-- --- osu! Performance & Zero Latency Rules ---
hl.window_rule({
    name = "osu-performance",
    match = { class = "^(osu!|osu)$" },
    immediate = true,
    fullscreen = true,
    no_blur = true,
    no_anim = true,
})
