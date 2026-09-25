-- ==============================================================================
-- Caelestia Shell - User Hyprland Overrides
-- Loaded automatically by ~/.config/hypr/hyprland.lua
-- ==============================================================================

-- Launch terminal explicitly at home directory (~)
hl.bind("SUPER + T", hl.dsp.exec_cmd("/home/diamond/.config/hypr/scripts/launch-terminal.sh --home"))

-- Windscribe VPN: Launch as floating without forced dimensions
-- Allows the app to dynamically autosize between collapsed (350x284) and expanded (350x600)
-- without graphical glitches.
hl.window_rule({
    match = { class = "^[Ww]indscribe$" },
    float = true,
})
