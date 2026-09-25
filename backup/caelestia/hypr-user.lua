-- ==============================================================================
-- Caelestia Shell - User Hyprland Overrides
-- Loaded automatically by ~/.config/hypr/hyprland.lua
-- ==============================================================================

-- Launch terminal explicitly at home directory (~)
hl.bind("SUPER + T", hl.dsp.exec_cmd("/home/diamond/.config/hypr/scripts/launch-terminal.sh --home"))

-- Move active window to special workspaces
hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special:special" }))
hl.bind("SUPER + ALT + W", hl.dsp.window.move({ workspace = "special:todo" }))
hl.bind("SUPER + ALT + D", hl.dsp.window.move({ workspace = "special:communication" }))
hl.bind("SUPER + ALT + M", hl.dsp.window.move({ workspace = "special:music" }))

-- Move active window out of special workspace to current normal workspace
hl.bind("SUPER + ALT + Down", hl.dsp.window.move({ workspace = "e+0" }))

-- Windscribe VPN: Launch as floating without forced dimensions
-- Allows the app to dynamically autosize between collapsed (350x284) and expanded (350x600)
-- without graphical glitches.
hl.window_rule({
    match = { class = "^[Ww]indscribe$" },
    float = true,
})
