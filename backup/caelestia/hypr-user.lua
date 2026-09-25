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

-- Swap active workspace with next or previous workspace (zero window re-arrangement)
hl.bind("CTRL + SUPER + ALT + Right", hl.dsp.exec_cmd("/home/diamond/.config/hypr/scripts/workspace-ctl.py swap-next"))
hl.bind("CTRL + SUPER + ALT + Left", hl.dsp.exec_cmd("/home/diamond/.config/hypr/scripts/workspace-ctl.py swap-prev"))

-- Shift (push) active workspace to next or previous workspace, cascading existing ones
hl.bind("CTRL + SUPER + ALT + SHIFT + Right", hl.dsp.exec_cmd("/home/diamond/.config/hypr/scripts/workspace-ctl.py shift-next"))
hl.bind("CTRL + SUPER + ALT + SHIFT + Left", hl.dsp.exec_cmd("/home/diamond/.config/hypr/scripts/workspace-ctl.py shift-prev"))
hl.bind("CTRL + SUPER + ALT + Page_Down", hl.dsp.exec_cmd("/home/diamond/.config/hypr/scripts/workspace-ctl.py shift-next"))
hl.bind("CTRL + SUPER + ALT + Page_Up", hl.dsp.exec_cmd("/home/diamond/.config/hypr/scripts/workspace-ctl.py shift-prev"))

-- Rebalance active workspace windows into an even grid (2x2 for 4 windows)
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("/home/diamond/.config/hypr/scripts/workspace-ctl.py balance"))

-- Windscribe VPN: Launch as floating without forced dimensions
-- Allows the app to dynamically autosize between collapsed (350x284) and expanded (350x600)
-- without graphical glitches.
hl.window_rule({
    match = { class = "^[Ww]indscribe$" },
    float = true,
})
