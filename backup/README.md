# System Configurations Backup

This folder contains a complete backup of all custom desktop, terminal, shell, wallpaper, and keybinding configurations configured for **Caelestia Shell** and **Hyprdark**.

---

## What is Backed Up

| Component | Path in Backup | Restores To | Details |
|---|---|---|---|
| **Wallpapers** | `wallpapers/*` | `~/Pictures/Wallpapers/` | Complete wallpaper collection (`bird1`, `eagle1`, `lara1`, `sadie1`, `spider1`, `ufc1`, `ufc2`) |
| **Wallpaper Timer** | `systemd/user/*` | `~/.config/systemd/user/` | Systemd service & timer automatically rotating wallpapers every 15 minutes (`caelestia wallpaper -r`) |
| **Zsh** | `zsh/.zshrc` | `~/.zshrc` | Cyber high-contrast prompt, execution timer, directory fill hairline, case-insensitive tab completion, Ctrl+Arrow/Alt+Arrow word jumping, pentest aliases |
| **Kitty** | `kitty/kitty.conf`<br>`kitty/theme.conf` | `~/.config/kitty/` | Font size 13.0, padding, cursor, cyber colors, Zsh shell integration |
| **Caelestia** | `caelestia/shell.json`<br>`caelestia/hypr-vars.lua`<br>`caelestia/monitors/` | `~/.config/caelestia/` | Audio status icon enabled, bar settings, app overrides (`Return` keybind, brave, dolphin, kitty) |
| **Hyprland** | `hypr/*` | `~/.config/hypr/` | Full Hyprland setup, `hyprland.lua`, `hyprland-gui.lua`, `scheme/`, `keybinds.lua`, `rules.lua` |
| **Spotify** | `spotify/spotify-flags.conf` | `~/.config/spotify-flags.conf` | Ozone Wayland flags (`UseOzonePlatform`, `wayland`) for crisp, non-pixelated native rendering |
| **Timezone** | *(Configured via script)* | `/etc/localtime` | Automatically sets system clock to **Turkiye Time** (`Europe/Istanbul`, UTC+3) |

---

## How to Restore on a Fresh Installation

After installing your base system and cloning this repository, simply run:

```bash
cd ~/Desktop/Github/shell/backup
./restore.sh
```

The restore script will:
1. Automatically set the system clock to Turkiye time (`Europe/Istanbul`).
2. Safely back up any existing files before replacing them (`*.bak.<timestamp>`).
3. Deploy all wallpapers and configuration files to their respective target paths in `~/.config/`, `~/Pictures/`, and `~/`.
4. Enable and start the 15-minute wallpaper rotation timer.
5. Reload Hyprland and Caelestia Shell if they are running.
