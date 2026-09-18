-- ==============================================================================
-- Caelestia Shell - User Hyprland Overrides
-- Loaded automatically by ~/.config/hypr/hyprland.lua
-- ==============================================================================

-- Windscribe VPN: Launch as floating without forced dimensions
-- Allows the app to dynamically autosize between collapsed (350x284) and expanded (350x600)
-- without graphical glitches.
hl.window_rule({
    match = { class = "^[Ww]indscribe$" },
    float = true,
})
